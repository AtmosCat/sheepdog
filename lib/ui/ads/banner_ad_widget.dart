import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class BannerAdWidget extends StatefulWidget {
  final bool isPremium; // 프리미엄 여부를 외부에서 전달받음
  const BannerAdWidget({
    super.key,
    required this.isPremium,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  final String testId = 'ca-app-pub-3940256099942544/6300978111';
  final String iosRealId = 'ca-app-pub-8181369336901289/5952152873';
  final String androidRealId = 'ca-app-pub-8181369336901289/1758559322';

  String get realId => Platform.isIOS ? iosRealId : androidRealId;

  @override
  void initState() {
    super.initState();

    if (widget.isPremium) return;

    _bannerAd = BannerAd(
      adUnitId: testId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (_, __) => setState(() => _isLoaded = false),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium) return const SizedBox.shrink();
    if (!_isLoaded) return const SizedBox.shrink();
    return SizedBox(
      height: 60,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
