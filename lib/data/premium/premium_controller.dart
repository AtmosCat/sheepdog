import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheepdog/core/premium/premium_config.dart';
import 'package:sheepdog/data/premium/iap_service.dart';
import 'package:sheepdog/data/premium/premium_access.dart';
import 'package:sheepdog/data/premium/premium_models.dart';
import 'package:sheepdog/data/premium/subscription_trial.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/ui/ads/admob_service.dart';
import 'package:sheepdog/ui/utils/fcm_utils.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';

class PremiumController extends ChangeNotifier with WidgetsBindingObserver {
  PremiumController() {
    unawaited(start());
  }

  static const _prefsKey = 'sheepdog_pro_entitlement';

  final IapService _iap = IapService();
  PremiumEntitlement _entitlement = PremiumEntitlement.free;
  Map<String, String> _storePrices = const {};
  Map<String, bool> _trialEligible = const {};
  var _storeReady = false;
  var _busy = false;
  var _started = false;
  var _buyingWithTrial = false;
  var _retryingPaidAfterTrial = false;
  PremiumPlan? _pendingPlan;

  PremiumEntitlement get entitlement => _entitlement;
  Map<String, String> get storePrices => _storePrices;
  bool get storeReady => _storeReady;
  bool get busy => _busy;
  bool get isPro => _entitlement.isPro;

  bool canStartFreeTrial(PremiumPlan plan) {
    if (isPro || _entitlement.hasUsedFreeTrial) return false;
    if (!_storeReady) return true;
    return _trialEligible[PremiumConfig.catalogKey(plan)] == true;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _entitlement = await _loadLocal();
      _applyAds(_entitlement.isPro);
      notifyListeners();

      await _iap.start(onPurchase: (purchase) {
        unawaited(_handlePurchase(purchase));
      });
      WidgetsBinding.instance.addObserver(this);
      _syncStoreCatalog();
      await _syncStoreEntitlement();
      await _syncFcm();
    } catch (e, st) {
      debugPrint('[Premium] start failed: $e\n$st');
    }
  }

  Future<void> buy(PremiumPlan plan) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      if (!_iap.hasProductFor(plan)) {
        debugPrint('[Premium] buy() queryProducts start');
        await _iap.queryProducts(userInitiated: true);
        debugPrint(
          '[Premium] buy() queryProducts done '
          'found=${_iap.products.keys.join(',')} error=${_iap.lastQueryError}',
        );
      }
      if (!_iap.hasProductFor(plan)) {
        _failBuy(_missingProductMessage);
        return;
      }
      _syncStoreCatalog();
      _pendingPlan = plan;
      final withTrial =
          canStartFreeTrial(plan) && _iap.trialAvailableFor(plan);
      _buyingWithTrial = withTrial;
      _retryingPaidAfterTrial = false;
      debugPrint(
        '[IAP] buy plan=${plan.name} id=${PremiumConfig.productIdFor(plan)} '
        'basePlan=${PremiumConfig.basePlanIdFor(plan)} withTrial=$withTrial '
        'canStart=${canStartFreeTrial(plan)} '
        'trialAvailable=${_iap.trialAvailableFor(plan)} '
        'storeReady=$_storeReady hasUsedTrial=${_entitlement.hasUsedFreeTrial}',
      );
      var ok = await _iap.buy(plan, withTrial: withTrial);
      if (!ok && withTrial) {
        debugPrint('[IAP] Trial launch failed; retrying paid plan=${plan.name}');
        _buyingWithTrial = false;
        ok = await _iap.buy(plan, withTrial: false);
      }
      if (!ok) {
        _failBuy(
          defaultTargetPlatform == TargetPlatform.iOS
              ? 'App Store가 ${plan.label} 상품(${PremiumConfig.productIdFor(plan)})을 열지 못했습니다. 구독 그룹과 상품 ID를 확인해 주세요.'
              : '스토어가 ${plan.label} 요금제를 열지 못했습니다. 기본 요금제 ID(${PremiumConfig.basePlanIdFor(plan)})를 확인해 주세요.',
        );
      }
    } catch (e, st) {
      debugPrint('[Premium] buy failed: $e\n$st');
      _failBuy('결제를 시작하지 못했습니다. 스토어 설정을 확인해 주세요.');
    }
  }

  String get _missingProductMessage {
    final error = _iap.lastQueryError;
    debugPrint('[Premium] missing product lastQueryError=$error');
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'App Store에서 구독 상품을 찾지 못했습니다. 구독 그룹 "${PremiumConfig.iosSubscriptionGroup}"에 ${PremiumConfig.iosMonthlyProductId}(월간), ${PremiumConfig.iosYearlyProductId}(연간)이 있는지 확인해 주세요.';
    }
    return '스토어에서 구독 상품(${PremiumConfig.playProductId})을 찾지 못했습니다. 콘솔에서 Active인지, 내부 테스트와 라이선스 테스터를 확인해 주세요.';
  }

  void _failBuy(String message) {
    _buyingWithTrial = false;
    _retryingPaidAfterTrial = false;
    SnackbarUtil.showToastMessage(message);
    _busy = false;
    notifyListeners();
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    try {
      if (purchase.status == PurchaseStatus.pending) {
        _busy = true;
        notifyListeners();
        return;
      }
      if (purchase.status == PurchaseStatus.error) {
        final code = purchase.error?.code ?? '';
        final message = purchase.error?.message ?? '';
        debugPrint('[IAP] Purchase error $code $message');
        await _iap.complete(purchase);
        if (_isItemUnavailable(message) &&
            _buyingWithTrial &&
            !_retryingPaidAfterTrial) {
          debugPrint(
            '[IAP] Trial offer unavailable; retrying auto-renewing base plan '
            '${purchase.productID}',
          );
          _buyingWithTrial = false;
          _retryingPaidAfterTrial = true;
          final ok = await _iap.buy(
            _pendingPlan ?? PremiumPlan.monthly,
            withTrial: false,
          );
          if (ok) return;
          _retryingPaidAfterTrial = false;
        }
        _buyingWithTrial = false;
        _retryingPaidAfterTrial = false;
        SnackbarUtil.showToastMessage(
          _isItemUnavailable(message)
              ? '이 계정으로 해당 요금제 혜택을 열 수 없습니다. 이미 체험·구독을 쓴 계정이면 스토어에서 구독을 해지한 뒤 다시 시도해 주세요.'
              : '결제에 실패했습니다. 잠시 후 다시 시도해 주세요.',
        );
        _busy = false;
        notifyListeners();
        return;
      }
      if (purchase.status == PurchaseStatus.canceled) {
        _buyingWithTrial = false;
        _retryingPaidAfterTrial = false;
        _busy = false;
        notifyListeners();
        await _iap.complete(purchase);
        return;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _retryingPaidAfterTrial = false;
        final plan = _pendingPlan ?? _iap.planFromPurchase(purchase);
        if (PremiumConfig.isKnownProduct(purchase.productID) || plan != null) {
          final startedTrial =
              _buyingWithTrial && purchase.status == PurchaseStatus.purchased;
          final now = DateTime.now();
          await _persist(
            PremiumEntitlement(
              isPro: true,
              plan: plan,
              productId: purchase.productID,
              source: purchase.status == PurchaseStatus.restored
                  ? PremiumSource.restore
                  : PremiumSource.iap,
              hasUsedFreeTrial: true,
              trialEndsAt: startedTrial
                  ? SubscriptionTrial.endsAtFrom(now)
                  : _entitlement.trialEndsAt,
              updatedAt: now,
            ),
          );
          if (purchase.status == PurchaseStatus.purchased) {
            SnackbarUtil.showToastMessage(
              startedTrial ? '7일 무료 체험이 시작되었습니다' : '쉽독 Pro 구독이 시작되었습니다',
            );
          }
        }
      }
      await _iap.complete(purchase);
    } catch (e, st) {
      debugPrint('[IAP] handlePurchase failed: $e\n$st');
    } finally {
      if (!_retryingPaidAfterTrial) {
        _buyingWithTrial = false;
        _busy = false;
        notifyListeners();
      }
    }
  }

  bool _isItemUnavailable(String message) {
    final value = message.toLowerCase();
    return value.contains('itemunavailable') ||
        value.contains('item_unavailable');
  }

  Future<void> _syncStoreEntitlement() async {
    if (!_iap.available) return;
    final active = await _iap.queryActiveSubscriptions();
    if (active == null) {
      debugPrint('[Premium] Skip entitlement sync; store query failed');
      return;
    }
    if (active.isNotEmpty) {
      final sub = active.first;
      await _persist(
        PremiumEntitlement(
          isPro: true,
          plan: sub.plan ??
              PremiumConfig.planForProduct(sub.productId) ??
              _entitlement.plan,
          productId: sub.productId,
          source: PremiumSource.restore,
          hasUsedFreeTrial: true,
          trialEndsAt: _entitlement.trialEndsAt,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }
    if (_entitlement.isPro) {
      debugPrint('[Premium] No active store subscription; reverting to free');
      await _persist(
        PremiumEntitlement(
          isPro: false,
          plan: _entitlement.plan,
          productId: _entitlement.productId,
          source: PremiumSource.none,
          hasUsedFreeTrial: true,
          trialEndsAt: _entitlement.trialEndsAt,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void _syncStoreCatalog() {
    final prices = <String, String>{};
    for (final plan in PremiumPlan.values) {
      final price = _iap.storePriceFor(plan);
      if (price != null) prices[PremiumConfig.catalogKey(plan)] = price;
    }
    _storePrices = prices;
    _trialEligible = Map<String, bool>.from(_iap.trialEligible);
    _storeReady = _iap.available;
    notifyListeners();
  }

  Future<PremiumEntitlement> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return PremiumEntitlement.free;
    try {
      return PremiumEntitlement.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return PremiumEntitlement.free;
    }
  }

  Future<void> _persist(PremiumEntitlement entitlement) async {
    _entitlement = entitlement;
    _applyAds(entitlement.isPro);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(entitlement.toJson()));
    await _syncFcm();
  }

  Future<void> _syncFcm() async {
    try {
      final subscriptions =
          await SubscriptionServiceRepository().getAllServices();
      await FCMUtils().saveUserNotificationSettings(
        subscriptions: subscriptions,
      );
    } catch (e) {
      debugPrint('[Premium] FCM sync failed: $e');
    }
  }

  void _applyAds(bool isPro) {
    PremiumAccess.isPro = isPro;
    AdMobService.setAdsRemoved(isPro);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncStoreEntitlement());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_iap.dispose());
    super.dispose();
  }
}
