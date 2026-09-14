import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:sheepdog/core/premium/premium_config.dart';
import 'package:sheepdog/data/premium/subscription_trial.dart';

void _iapLog(String message) => debugPrint('[IAP] $message');

class ActiveStoreSubscription {
  const ActiveStoreSubscription({
    required this.productId,
    this.plan,
    this.expiresAt,
  });

  final String productId;
  final PremiumPlan? plan;
  final DateTime? expiresAt;
}

class IapService {
  IapService();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  void Function(PurchaseDetails purchase)? _onPurchase;
  var available = false;
  final _offersByProduct = <String, List<ProductDetails>>{};
  final trialEligible = <String, bool>{};
  Future<void>? _queryInFlight;
  String? lastQueryError;

  bool get hasPlayProduct =>
      (_offersByProduct[PremiumConfig.playProductId] ?? const []).isNotEmpty;

  Map<String, ProductDetails> get products {
    return {
      for (final entry in _offersByProduct.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value.first,
    };
  }

  bool get supported {
    if (kIsWeb) return false;
    if (const bool.fromEnvironment('FLUTTER_TEST')) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> start({
    required void Function(PurchaseDetails purchase) onPurchase,
  }) async {
    _onPurchase = onPurchase;
    if (!supported) {
      _iapLog('Skip start (unsupported platform or test)');
      return;
    }
    try {
      available = await _iap
          .isAvailable()
          .timeout(const Duration(seconds: 8));
    } catch (e, st) {
      lastQueryError = 'unavailable';
      _iapLog('isAvailable failed: $e\n$st');
      available = false;
      return;
    }
    if (!available) {
      lastQueryError = 'unavailable';
      _iapLog('Store not available yet');
      return;
    }
    _listenPurchases();
    await queryProducts();
  }

  Future<void> queryProducts({bool userInitiated = false}) async {
    if (hasPlayProduct) {
      lastQueryError = null;
      return;
    }
    if (_queryInFlight != null) {
      _iapLog(
        'queryProductDetails already in flight; '
        'userInitiated=$userInitiated lastError=$lastQueryError',
      );
      await _queryInFlight;
      return;
    }
    lastQueryError = null;
    final future = _queryProductsBody();
    _queryInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_queryInFlight, future)) {
        _queryInFlight = null;
      }
    }
  }

  Future<void> _queryProductsBody() async {
    if (!await _ensureAvailable()) {
      lastQueryError = 'unavailable';
      _iapLog('queryProductDetails skipped; store unavailable');
      return;
    }
    try {
      final ids = PremiumConfig.queryProductIds;
      _iapLog('queryProductDetails start ids=${ids.join(', ')}');
      final response = await _iap
          .queryProductDetails(ids)
          .timeout(const Duration(seconds: 20));
      if (response.error != null) {
        lastQueryError =
            '${response.error!.code} ${response.error!.message}';
        _iapLog(
          'queryProductDetails error ${response.error!.code} '
          '${response.error!.message} details=${response.error!.details}',
        );
      }
      if (response.notFoundIDs.isNotEmpty) {
        lastQueryError ??= 'not_found:${response.notFoundIDs.join(',')}';
        _iapLog('Products not found: ${response.notFoundIDs.join(', ')}');
      }
      _offersByProduct.clear();
      for (final product in response.productDetails) {
        _offersByProduct.putIfAbsent(product.id, () => []).add(product);
        _logProduct(product);
      }
      if (hasPlayProduct) {
        lastQueryError = null;
      } else {
        lastQueryError ??= 'empty';
      }
      _iapLog(
        'queryProductDetails done count=${response.productDetails.length} '
        'ids=${_offersByProduct.keys.join(', ')} error=$lastQueryError',
      );
      _logCatalog();
      await _refreshTrialEligibility();
    } on TimeoutException {
      lastQueryError = 'timeout';
      _iapLog('queryProductDetails TIMED OUT after 20s');
    } catch (e, st) {
      lastQueryError = e.toString();
      _iapLog('queryProductDetails threw: $e\n$st');
    }
  }

  bool trialAvailableFor(PremiumPlan plan) =>
      trialEligible[PremiumConfig.catalogKey(plan)] == true;

  String? storePriceFor(PremiumPlan plan) {
    final offers = _offersFor(plan);
    if (offers.isEmpty) return null;
    for (final product in offers) {
      if (product is GooglePlayProductDetails) {
        final paid = _playPaidPrice(product, plan);
        if (paid != null) return paid;
      }
    }
    final matching = offers.where((product) => _offerMatchesPlan(product, plan));
    return (matching.isNotEmpty ? matching.first : offers.first).price;
  }

  Future<bool> buy(PremiumPlan plan, {required bool withTrial}) async {
    if (!await _ensureAvailable()) {
      _iapLog('buy skipped; store unavailable');
      return false;
    }
    final offers = _offersFor(plan);
    if (offers.isEmpty) {
      _iapLog(
        'buy skipped; product missing plan=${plan.name} '
        'id=${PremiumConfig.productIdFor(plan)}',
      );
      return false;
    }
    try {
      _iapLog(
        'buy start plan=${plan.name} withTrial=$withTrial '
        'offerCount=${offers.length}',
      );
      final param = _purchaseParam(
        offers: offers,
        plan: plan,
        withTrial: withTrial,
      );
      if (param == null) {
        _iapLog(
          'buy skipped; no purchase param plan=${plan.name} '
          'basePlan=${PremiumConfig.basePlanIdFor(plan)} withTrial=$withTrial',
        );
        return false;
      }
      _iapLog(
        'launchBillingFlow id=${param.productDetails.id} '
        'plan=${plan.name} withTrial=$withTrial',
      );
      final ok = await _iap.buyNonConsumable(purchaseParam: param);
      if (!ok) {
        _iapLog(
          'launchBillingFlow returned false id=${param.productDetails.id} '
          'plan=${plan.name}',
        );
      }
      return ok;
    } catch (e, st) {
      _iapLog('buyNonConsumable threw: $e\n$st');
      return false;
    }
  }

  Future<List<ActiveStoreSubscription>?> queryActiveSubscriptions() async {
    if (!await _ensureAvailable()) return const [];
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _queryAndroidSubscriptions();
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _queryIosSubscriptions();
      }
      return const [];
    } catch (e, st) {
      _iapLog('queryActiveSubscriptions failed: $e\n$st');
      return null;
    }
  }

  Future<void> complete(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(purchase);
    } catch (e, st) {
      _iapLog('completePurchase failed: $e\n$st');
    }
  }

  PremiumPlan? planFromPurchase(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      final fromJson = _basePlanFromPurchaseJson(
        purchase.billingClientPurchase.originalJson,
      );
      final fromBase = PremiumConfig.planForBasePlan(fromJson);
      if (fromBase != null) return fromBase;
    }
    return PremiumConfig.planForProduct(purchase.productID);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _listenPurchases() {
    final onPurchase = _onPurchase;
    if (onPurchase == null) return;
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen(
      (purchases) {
        for (final purchase in purchases) {
          _iapLog('Purchase ${purchase.productID} status=${purchase.status}');
          onPurchase(purchase);
        }
      },
      onError: (Object e, StackTrace st) {
        _iapLog('purchaseStream error: $e\n$st');
      },
    );
  }

  Future<bool> _ensureAvailable() async {
    if (!supported) return false;
    if (available && _sub != null) return true;
    try {
      available = await _iap
          .isAvailable()
          .timeout(const Duration(seconds: 8));
    } catch (e, st) {
      _iapLog('isAvailable failed: $e\n$st');
      available = false;
      return false;
    }
    if (!available) return false;
    if (_sub == null) _listenPurchases();
    return true;
  }

  PurchaseParam? _purchaseParam({
    required List<ProductDetails> offers,
    required PremiumPlan plan,
    required bool withTrial,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final playOffers = offers.whereType<GooglePlayProductDetails>().toList();
      GooglePlayProductDetails? selected;
      if (withTrial) {
        for (final offer in playOffers) {
          final details = _playOffer(offer);
          if (details != null &&
              _matchesBasePlan(details, plan) &&
              details.offerId == PremiumConfig.playTrialOfferId) {
            selected = offer;
            break;
          }
        }
        if (selected == null) {
          for (final offer in playOffers) {
            if (_isPlayTrialOffer(offer, plan)) {
              selected = offer;
              break;
            }
          }
        }
      }
      selected ??= _playPaidOffer(playOffers, plan);
      if (selected == null) {
        final basePlans = playOffers
            .map((offer) => _playOffer(offer)?.basePlanId)
            .whereType<String>()
            .toSet()
            .join(', ');
        _iapLog(
          'buy skipped; no matching basePlan='
          '${PremiumConfig.basePlanIdFor(plan)} available=[$basePlans]',
        );
        return null;
      }
      _logPlayOffers(playOffers, selected: selected, withTrial: withTrial);
      final token = selected.offerToken;
      if (token == null || token.isEmpty) {
        _iapLog('buy skipped; empty offerToken id=${selected.id}');
        return null;
      }
      return GooglePlayPurchaseParam(
        productDetails: selected,
        offerToken: token,
      );
    }

    final matching = offers.where((product) => _offerMatchesPlan(product, plan));
    final product = matching.isNotEmpty ? matching.first : null;
    if (product == null) {
      _iapLog(
        'buy skipped; no iOS product plan=${plan.name} '
        'id=${PremiumConfig.productIdFor(plan)}',
      );
      return null;
    }
    if (product is AppStoreProduct2Details) {
      return Sk2PurchaseParam(productDetails: product);
    }
    return PurchaseParam(productDetails: product);
  }

  List<ProductDetails> _offersFor(PremiumPlan plan) {
    return List<ProductDetails>.from(
      _offersByProduct[PremiumConfig.playProductId] ?? const [],
    );
  }

  bool _offerMatchesPlan(ProductDetails product, PremiumPlan plan) {
    if (product is GooglePlayProductDetails) {
      final offer = _playOffer(product);
      if (offer == null) return false;
      return _matchesBasePlan(offer, plan);
    }
    return product.id == PremiumConfig.playProductId;
  }

  Future<void> _refreshTrialEligibility() async {
    trialEligible.clear();
    for (final plan in PremiumPlan.values) {
      trialEligible[PremiumConfig.catalogKey(plan)] =
          await _isTrialEligible(plan);
    }
    _iapLog(
      'Trial eligibility monthly=${trialEligible[PremiumConfig.catalogKey(PremiumPlan.monthly)]} '
      'yearly=${trialEligible[PremiumConfig.catalogKey(PremiumPlan.yearly)]}',
    );
  }

  Future<bool> _isTrialEligible(PremiumPlan plan) async {
    final offers = _offersFor(plan);
    if (offers.isEmpty) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      for (final product in offers.whereType<GooglePlayProductDetails>()) {
        final playOffers = product.productDetails.subscriptionOfferDetails;
        if (playOffers == null) continue;
        if (playOffers.any(
          (offer) =>
              _matchesBasePlan(offer, plan) && _playOfferLooksLikeTrial(offer),
        )) {
          return true;
        }
      }
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      for (final product in offers) {
        if (product is AppStoreProductDetails) {
          final intro = product.skProduct.introductoryPrice;
          if (intro != null &&
              intro.paymentMode == SKProductDiscountPaymentMode.freeTrail) {
            return true;
          }
        }
        if (product is AppStoreProduct2Details) {
          final info = product.sk2Product.subscription;
          if (info != null &&
              info.promotionalOffers.any(
                (offer) =>
                    offer.type == SK2SubscriptionOfferType.introductory &&
                    offer.paymentMode ==
                        SK2SubscriptionOfferPaymentMode.freeTrial,
              )) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<List<ActiveStoreSubscription>> _queryAndroidSubscriptions() async {
    final addition =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      _iapLog(
        'queryPastPurchases ${response.error!.code} ${response.error!.message}',
      );
      throw StateError(response.error!.message);
    }
    final active = <ActiveStoreSubscription>[];
    for (final purchase in response.pastPurchases) {
      if (!PremiumConfig.isKnownProduct(purchase.productID)) continue;
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }
      if (purchase.billingClientPurchase.purchaseState !=
          PurchaseStateWrapper.purchased) {
        continue;
      }
      active.add(
        ActiveStoreSubscription(
          productId: purchase.productID,
          plan: planFromPurchase(purchase),
        ),
      );
    }
    return active;
  }

  Future<List<ActiveStoreSubscription>> _queryIosSubscriptions() async {
    final transactions = await SK2Transaction.transactions();
    final now = DateTime.now();
    final active = <ActiveStoreSubscription>[];
    for (final tx in transactions) {
      if (!PremiumConfig.isKnownProduct(tx.productId)) continue;
      final expiresAt = SubscriptionTrial.tryParseStoreDate(tx.expirationDate);
      if (expiresAt == null || !expiresAt.isAfter(now)) continue;
      active.add(
        ActiveStoreSubscription(
          productId: tx.productId,
          plan: PremiumConfig.planForProduct(tx.productId),
          expiresAt: expiresAt,
        ),
      );
    }
    return active;
  }

  void _logProduct(ProductDetails product) {
    if (product is GooglePlayProductDetails) {
      final offer = _playOffer(product);
      final all = product.productDetails.subscriptionOfferDetails;
      _iapLog(
        'product id=${product.id} title=${product.title} price=${product.price} '
        'index=${product.subscriptionIndex} '
        'offerCount=${all?.length ?? 0} '
        'basePlan=${offer?.basePlanId} offerId=${offer?.offerId} '
        'tokenLen=${offer?.offerIdToken.length}',
      );
      if (all != null) {
        for (final item in all) {
          _iapLog(
            '  offer basePlan=${item.basePlanId} offerId=${item.offerId} '
            'tags=${item.offerTags.join(',')} '
            'phases=${item.pricingPhases.map((p) => '${p.formattedPrice}/${p.billingPeriod}/${p.priceAmountMicros}/${p.recurrenceMode.name}').join(' | ')}',
          );
        }
      }
      return;
    }
    _iapLog(
      'product id=${product.id} title=${product.title} price=${product.price}',
    );
  }

  void _logCatalog() {
    for (final plan in PremiumPlan.values) {
      final offers = _offersFor(plan);
      _iapLog(
        'catalog ${plan.name} count=${offers.length} '
        'price=${storePriceFor(plan)}',
      );
    }
  }

  void _logPlayOffers(
    List<GooglePlayProductDetails> offers, {
    required GooglePlayProductDetails selected,
    required bool withTrial,
  }) {
    for (final product in offers) {
      final offer = _playOffer(product);
      if (offer == null) continue;
      _iapLog(
        'Offer id=${product.id} basePlan=${offer.basePlanId} '
        'offerId=${offer.offerId} tags=${offer.offerTags.join(',')} '
        'tokenLen=${offer.offerIdToken.length} '
        'selected=${identical(product, selected)} '
        'withTrial=$withTrial '
        'phases=${offer.pricingPhases.map((p) => '${p.formattedPrice}/${p.billingPeriod}/${p.priceAmountMicros}/${p.recurrenceMode.name}').join(' | ')}',
      );
    }
  }

  bool _matchesBasePlan(
    SubscriptionOfferDetailsWrapper offer,
    PremiumPlan plan,
  ) {
    return PremiumConfig.planForBasePlan(offer.basePlanId) == plan;
  }

  bool _isPlayTrialOffer(GooglePlayProductDetails product, PremiumPlan plan) {
    final offer = _playOffer(product);
    if (offer == null) return false;
    if (!_matchesBasePlan(offer, plan)) return false;
    return _playOfferLooksLikeTrial(offer);
  }

  bool _playOfferLooksLikeTrial(SubscriptionOfferDetailsWrapper offer) {
    if (PremiumConfig.isPlayTrialOffer(
      offerId: offer.offerId,
      offerTags: offer.offerTags,
    )) {
      return true;
    }
    if (offer.pricingPhases.isEmpty) return false;
    final first = offer.pricingPhases.first;
    return first.priceAmountMicros == 0 &&
        SubscriptionTrial.isSevenDayPeriod(first.billingPeriod);
  }

  bool _isAutoRenewingBase(GooglePlayProductDetails product, PremiumPlan plan) {
    final details = _playOffer(product);
    if (details == null) return false;
    if (!_matchesBasePlan(details, plan)) return false;
    if (_playOfferLooksLikeTrial(details)) return false;
    if (details.offerId != null && details.offerId!.isNotEmpty) return false;
    return details.pricingPhases.any(
      (phase) =>
          phase.priceAmountMicros > 0 &&
          phase.recurrenceMode == RecurrenceMode.infiniteRecurring,
    );
  }

  GooglePlayProductDetails? _playPaidOffer(
    List<GooglePlayProductDetails> offers,
    PremiumPlan plan,
  ) {
    for (final offer in offers) {
      if (_isAutoRenewingBase(offer, plan)) return offer;
    }
    for (final offer in offers) {
      final details = _playOffer(offer);
      if (details == null) continue;
      if (_matchesBasePlan(details, plan) && !_isPlayTrialOffer(offer, plan)) {
        return offer;
      }
    }
    return null;
  }

  SubscriptionOfferDetailsWrapper? _playOffer(GooglePlayProductDetails product) {
    final index = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return null;
    return offers[index];
  }

  String? _playPaidPrice(GooglePlayProductDetails product, PremiumPlan plan) {
    final offers = product.productDetails.subscriptionOfferDetails;
    if (offers == null) return null;
    final candidates = offers
        .where((offer) => PremiumConfig.planForBasePlan(offer.basePlanId) == plan)
        .toList();
    final priced = candidates.isEmpty ? offers : candidates;
    for (final offer in priced) {
      for (final phase in offer.pricingPhases) {
        if (phase.priceAmountMicros > 0 &&
            phase.recurrenceMode == RecurrenceMode.infiniteRecurring) {
          return PremiumConfig.formatKrwMicros(
                phase.priceAmountMicros,
                phase.priceCurrencyCode,
              ) ??
              phase.formattedPrice;
        }
      }
    }
    return null;
  }

  String? _basePlanFromPurchaseJson(String originalJson) {
    try {
      final decoded = jsonDecode(originalJson);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final direct = map['basePlanId'] as String?;
      if (direct != null && direct.isNotEmpty) return direct;
      final nested = map['subscriptionOfferDetails'];
      if (nested is Map && nested['basePlanId'] is String) {
        return nested['basePlanId'] as String;
      }
    } catch (_) {}
    return null;
  }
}
