import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/ads/admob_constants.dart';

class BannerAdWidget extends StatefulWidget {
  final bool isPremium;

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
  int _loadAttempts = 0;

  static double get _bannerHeight => AdSize.banner.height.toDouble();

  @override
  void initState() {
    super.initState();
    if (widget.isPremium || !AdMobConstants.isSupportedNativePlatform) return;
    _loadBanner();
  }

  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPremium && widget.isPremium) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isLoaded = false;
    } else if (oldWidget.isPremium && !widget.isPremium) {
      _loadAttempts = 0;
      _loadBanner();
    }
  }

  void _loadBanner() {
    final unitId = AdMobConstants.bannerAdUnitId;
    if (unitId.isEmpty) return;

    _bannerAd?.dispose();
    _isLoaded = false;
    _bannerAd = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('[AdMob] banner loaded: $unitId');
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] banner load failed: $error');
          ad.dispose();
          _bannerAd = null;
          if (!mounted) return;
          setState(() => _isLoaded = false);
          if (_loadAttempts < 3) {
            _loadAttempts++;
            Future.delayed(Duration(seconds: 2 * _loadAttempts), () {
              if (mounted && !widget.isPremium) _loadBanner();
            });
          }
        },
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
    if (widget.isPremium || !AdMobConstants.isSupportedNativePlatform) {
      return const SizedBox.shrink();
    }

    final topInset = MediaQuery.viewPaddingOf(context).top;

    return ColoredBox(
      color: AppColor.containerWhite.of(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topInset),
          SizedBox(
            width: double.infinity,
            height: _bannerHeight,
            child: _isLoaded && _bannerAd != null
                ? Center(child: AdWidget(ad: _bannerAd!))
                : const ColoredBox(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
