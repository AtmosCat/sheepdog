import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AndroidNativeAdWidget extends StatefulWidget {
  const AndroidNativeAdWidget({super.key});

  @override
  State<AndroidNativeAdWidget> createState() => _AndroidNativeAdWidgetState();
}

class _AndroidNativeAdWidgetState extends State<AndroidNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  final String testId = 'ca-app-pub-3940256099942544/2247696110';
  final String realId = 'ca-app-pub-8181369336901289/6722293158';

  @override
  void initState() {
    super.initState();
    _nativeAd = NativeAd(
      adUnitId: testId,
      factoryId: 'adFactoryExample', // 반드시 플랫폼별로 factory 등록 필요
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() => _isLoaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox(height: 120);
    return SizedBox(height: 120, child: AdWidget(ad: _nativeAd!));
  }
}
