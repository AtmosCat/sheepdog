import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AppOpenAdManager {
  final String iosRealId = 'ca-app-pub-8181369336901289/3457001418';
  final String androidRealId = 'ca-app-pub-8181369336901289/8132395984';

  Future<void> showAppOpenAdIfAvailable({
    required VoidCallback onClosed,
    required bool isPremium,
  }) async {
    if (isPremium) {
      onClosed();
      return;
    }

    final String testId = 'ca-app-pub-3940256099942544/9257395921';
    final relaId = Platform.isIOS ? iosRealId : androidRealId;
    // 임시 비활성화
    // await AppOpenAd.load(
    //   adUnitId: testId,
    //   request: const AdRequest(),
    //   adLoadCallback: AppOpenAdLoadCallback(
    //     onAdLoaded: (ad) {
    //       ad.fullScreenContentCallback = FullScreenContentCallback(
    //         onAdDismissedFullScreenContent: (ad) {
    //           ad.dispose();
    //           onClosed();
    //         },
    //         onAdFailedToShowFullScreenContent: (ad, error) {
    //           ad.dispose();
    //           onClosed();
    //         },
    //       );
    //       ad.show();
    //     },
    //     onAdFailedToLoad: (error) {
    //       onClosed();
    //     },
    //   ),
    // );
  }
}
