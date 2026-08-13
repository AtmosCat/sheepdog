import 'package:flutter/foundation.dart';

class AdMobConstants {
  AdMobConstants._();

  static bool get isSupportedNativePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get bannerAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-8181369336901289/2035798057';
      case TargetPlatform.iOS:
        return 'ca-app-pub-8181369336901289/5952152873';
      default:
        return '';
    }
  }

  static String get appOpenAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-8181369336901289/3832361389';
      case TargetPlatform.iOS:
        return 'ca-app-pub-8181369336901289/3457001418';
      default:
        return '';
    }
  }

  static String get subscriptionInterstitialAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-8181369336901289/3348879724';
      case TargetPlatform.iOS:
        return 'ca-app-pub-8181369336901289/9830838077';
      default:
        return '';
    }
  }
}
