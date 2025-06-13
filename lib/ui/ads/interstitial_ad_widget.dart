import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class InterstitialAdWidget extends StatelessWidget {
  const InterstitialAdWidget({super.key});

  Future<void> showInterstitialAdIfAvailable({
    required VoidCallback onClosed,
    bool useTestAd = true,
  }) async {
    final String testId = 'ca-app-pub-3940256099942544/1033173712';
    final String iosRealId = 'ca-app-pub-8181369336901289/9830838077';
    final String androidRealId = 'ca-app-pub-8181369336901289/6275586509';

    await InterstitialAd.load(
      adUnitId: useTestAd ? testId : androidRealId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onClosed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onClosed();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          onClosed();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showInterstitialAdIfAvailable(
          onClosed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('광고가 닫혔습니다.')));
          },
        );
      },
      child: const Text('전면 광고 보기'),
    );
  }
}
