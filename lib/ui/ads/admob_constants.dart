import 'package:flutter/foundation.dart';

class AdMobConstants {
  AdMobConstants._();

  static bool get isSupportedNativePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get useTestAds => kDebugMode;

  static String get bannerAdUnitId => _unitId(
        android: 'ca-app-pub-8181369336901289/2035798057',
        ios: 'ca-app-pub-8181369336901289/5952152873',
        androidTest: 'ca-app-pub-3940256099942544/6300978111',
        iosTest: 'ca-app-pub-3940256099942544/2934735716',
      );

  static String get appOpenAdUnitId => _unitId(
        android: 'ca-app-pub-8181369336901289/3832361389',
        ios: 'ca-app-pub-8181369336901289/3457001418',
        androidTest: 'ca-app-pub-3940256099942544/9257395921',
        iosTest: 'ca-app-pub-3940256099942544/5575463023',
      );

  static String get subscriptionInterstitialAdUnitId => _unitId(
        android: 'ca-app-pub-8181369336901289/3348879724',
        ios: 'ca-app-pub-8181369336901289/9830838077',
        androidTest: 'ca-app-pub-3940256099942544/1033173712',
        iosTest: 'ca-app-pub-3940256099942544/4411468910',
      );

  static String _unitId({
    required String android,
    required String ios,
    required String androidTest,
    required String iosTest,
  }) {
    final test = useTestAds;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return test ? androidTest : android;
      case TargetPlatform.iOS:
        return test ? iosTest : ios;
      default:
        return '';
    }
  }
}
