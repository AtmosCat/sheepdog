import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  late BannerAd _bannerAd;
  bool _isLoaded = false;
  final String testId = 'ca-app-pub-3940256099942544/6300978111';
  final String iosRealId = 'ca-app-pub-8181369336901289/5952152873';
  final String androidRealId = 'ca-app-pub-8181369336901289/1758559322';

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: testId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (_, __) => setState(() => _isLoaded = false),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox(height: 50);
    return SizedBox(
      height: 60,
      child: AdWidget(ad: _bannerAd),
    );
  }
}
