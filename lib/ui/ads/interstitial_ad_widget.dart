import 'package:flutter/material.dart';
import 'package:sheepdog/ui/ads/admob_service.dart';

class InterstitialAdWidget {
  const InterstitialAdWidget({required this.isPremium});

  final bool isPremium;

  Future<void> showInterstitialAdIfAvailable({
    required VoidCallback onClosed,
  }) async {
    if (isPremium) {
      onClosed();
      return;
    }

    await AdMobService.showSubscriptionInterstitial(onClosed: onClosed);
  }
}
