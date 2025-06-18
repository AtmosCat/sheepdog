import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  // 실제 광고 단위 ID (실제 사용 시 교체)
  final String androidRealId = 'ca-app-pub-8181369336901289/6722293158';
  final String iosRealId = 'ca-app-pub-8181369336901289/6083164757';

  // 플랫폼별 factoryId
  final String factoryId = 'adFactoryExample';

  @override
  void initState() {
    super.initState();

    // 테스트용 ID (실제 사용 시 realId로 교체)
    final testId = 'ca-app-pub-3940256099942544/2247696110';
    final realId = Platform.isIOS ? iosRealId : androidRealId;

    _nativeAd = NativeAd(
      adUnitId: testId,
      factoryId: factoryId,
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
