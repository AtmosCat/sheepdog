import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheepdog/ui/ads/admob_constants.dart';

/// dont-worry 프로젝트의 App Open / Interstitial 패턴을 따릅니다.
class AdMobService {
  AdMobService._();

  static const Duration maxCacheDuration = Duration(hours: 4);

  static bool _initialized = false;
  static AppOpenAd? _appOpenAd;
  static DateTime? _appOpenLoadTime;
  static bool _isShowingAppOpenAd = false;
  static bool _isLoadingAppOpenAd = false;
  static final List<void Function()> _appOpenLoadedListeners = [];
  static final List<void Function(LoadAdError error)> _appOpenFailedListeners =
      [];
  static InterstitialAd? _subscriptionInterstitialAd;
  static const String _interstitialSaveCountKey =
      'admob_interstitial_save_count';
  /// 구독 저장 N회마다 전면 1회 (2 = 2회마다 1번)
  static const int interstitialEveryNSaves = 2;
  static bool _adsRemoved = false;

  static bool get isAppOpenAdAvailable => _appOpenAd != null;
  static bool get adsRemoved => _adsRemoved;

  static void setAdsRemoved(bool removed) {
    _adsRemoved = removed;
    if (!removed) return;
    _subscriptionInterstitialAd?.dispose();
    _subscriptionInterstitialAd = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }

  static Future<void> initialize() async {
    if (_adsRemoved || _initialized || !AdMobConstants.isSupportedNativePlatform) {
      return;
    }

    if (AdMobConstants.useTestAds) {
      debugPrint('[AdMob] debug build: using Google test ad units');
    }

    final status = await MobileAds.instance.initialize();
    debugPrint('[AdMob] initialized: ${status.adapterStatuses}');
    _initialized = true;

    // 앱 오프닝은 정책상 비활성화. 전면만 미리 로드.
    _loadSubscriptionInterstitial();
  }

  static void loadAppOpenAd({
    void Function()? onLoaded,
    void Function(LoadAdError error)? onFailedToLoad,
  }) {
    if (_adsRemoved ||
        !AdMobConstants.isSupportedNativePlatform ||
        !_initialized) {
      return;
    }

    if (_appOpenAd != null) {
      onLoaded?.call();
      return;
    }

    if (onLoaded != null) _appOpenLoadedListeners.add(onLoaded);
    if (onFailedToLoad != null) {
      _appOpenFailedListeners.add(onFailedToLoad);
    }

    if (_isLoadingAppOpenAd) return;

    final unitId = AdMobConstants.appOpenAdUnitId;
    if (unitId.isEmpty) {
      _appOpenLoadedListeners.clear();
      _appOpenFailedListeners.clear();
      return;
    }

    _isLoadingAppOpenAd = true;

    AppOpenAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isLoadingAppOpenAd = false;
          final listeners = List<void Function()>.from(_appOpenLoadedListeners);
          _appOpenLoadedListeners.clear();
          _appOpenFailedListeners.clear();
          for (final listener in listeners) {
            listener();
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] app-open load failed: $error');
          _isLoadingAppOpenAd = false;
          final listeners =
              List<void Function(LoadAdError)>.from(_appOpenFailedListeners);
          _appOpenLoadedListeners.clear();
          _appOpenFailedListeners.clear();
          for (final listener in listeners) {
            listener(error);
          }
        },
      ),
    );
  }

  static Future<bool> showAppOpenAdIfAvailable() async {
    if (!_initialized) return false;
    if (_isShowingAppOpenAd) return false;

    final ad = _appOpenAd;
    final loadTime = _appOpenLoadTime;
    if (ad == null || loadTime == null) {
      loadAppOpenAd();
      return false;
    }

    if (DateTime.now().subtract(maxCacheDuration).isAfter(loadTime)) {
      ad.dispose();
      _appOpenAd = null;
      _appOpenLoadTime = null;
      loadAppOpenAd();
      return false;
    }

    final completer = Completer<void>();
    _appOpenAd = null;
    _appOpenLoadTime = null;
    _isShowingAppOpenAd = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] app-open show failed: $error');
        _isShowingAppOpenAd = false;
        ad.dispose();
        loadAppOpenAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        loadAppOpenAd();
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      await ad.show();
    } catch (error) {
      debugPrint('[AdMob] app-open show threw: $error');
      _isShowingAppOpenAd = false;
      ad.dispose();
      loadAppOpenAd();
      if (!completer.isCompleted) completer.complete();
      return false;
    }

    await completer.future;
    return true;
  }

  static Future<void> showAppOpenAdFromLoadingScreen({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (!_initialized) return;

    if (isAppOpenAdAvailable) {
      await showAppOpenAdIfAvailable();
      return;
    }

    final completer = Completer<void>();
    var finished = false;

    void finish() {
      if (finished) return;
      finished = true;
      if (!completer.isCompleted) completer.complete();
    }

    loadAppOpenAd(
      onLoaded: () async {
        if (finished) return;
        await showAppOpenAdIfAvailable();
        finish();
      },
      onFailedToLoad: (_) => finish(),
    );

    Future.delayed(timeout, () {
      if (!finished) finish();
    });

    await completer.future;
  }

  static Future<void> showSubscriptionInterstitial({
    required void Function() onClosed,
  }) async {
    if (_adsRemoved || !_initialized) {
      onClosed();
      return;
    }

    // 저장 시도 횟수 증가 후, N회마다만 전면 노출
    final prefs = await SharedPreferences.getInstance();
    final nextCount = (prefs.getInt(_interstitialSaveCountKey) ?? 0) + 1;
    await prefs.setInt(_interstitialSaveCountKey, nextCount);

    final shouldShow = nextCount % interstitialEveryNSaves == 0;
    if (!shouldShow) {
      debugPrint(
        '[AdMob] interstitial skipped ($nextCount / $interstitialEveryNSaves)',
      );
      onClosed();
      return;
    }

    final ad = _subscriptionInterstitialAd;
    if (ad == null) {
      _loadSubscriptionInterstitial();
      onClosed();
      return;
    }

    _subscriptionInterstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadSubscriptionInterstitial();
        onClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] interstitial show failed: $error');
        ad.dispose();
        _loadSubscriptionInterstitial();
        onClosed();
      },
    );
    ad.show();
  }

  static void _loadSubscriptionInterstitial() {
    if (_adsRemoved || !AdMobConstants.isSupportedNativePlatform) return;
    final unitId = AdMobConstants.subscriptionInterstitialAdUnitId;
    if (unitId.isEmpty) return;

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] interstitial loaded: $unitId');
          _subscriptionInterstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] interstitial load failed: $error');
          // No fill 등으로 실패한 경우 잠시 후 재시도
          Future.delayed(const Duration(seconds: 30), () {
            if (_subscriptionInterstitialAd == null) {
              _loadSubscriptionInterstitial();
            }
          });
        },
      ),
    );
  }
}
