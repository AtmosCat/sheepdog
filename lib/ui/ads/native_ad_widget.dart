import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sheepdog/ui/ads/admob_constants.dart';

class NativeAdWidget extends StatefulWidget {
  final double height;

  const NativeAdWidget({
    super.key,
    this.height = 88,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  int _loadAttempts = 0;

  @override
  void initState() {
    super.initState();
    if (!AdMobConstants.isSupportedNativePlatform) return;
    _loadNative();
  }

  void _loadNative() {
    final unitId = AdMobConstants.nativeAdUnitId;
    if (unitId.isEmpty) return;

    _nativeAd?.dispose();
    _nativeAd = NativeAd(
      adUnitId: unitId,
      factoryId: AdMobConstants.nativeAdFactoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] native loaded: $unitId');
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] native load failed: $error');
          ad.dispose();
          _nativeAd = null;
          if (!mounted) return;
          setState(() => _isLoaded = false);
          if (_loadAttempts < 3) {
            _loadAttempts++;
            Future.delayed(Duration(seconds: 2 * _loadAttempts), () {
              if (mounted) _loadNative();
            });
          }
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
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
