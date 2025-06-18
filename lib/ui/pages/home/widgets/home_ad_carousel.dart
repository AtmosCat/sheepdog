import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/ads/native_ad_widget.dart';
import 'package:sheepdog/ui/pages/mypage/widgets/show_paid_app_info_dialog.dart';

class HomeAdCarousel extends StatefulWidget {
  const HomeAdCarousel({super.key});

  @override
  State<HomeAdCarousel> createState() => _HomeAdCarouselState();
}

class _HomeAdCarouselState extends State<HomeAdCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  static const int totalAds = 10;

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      int nextPage = (_pageController.page?.round() ?? 0) + 1;
      if (nextPage >= totalAds) nextPage = 0;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildCustomAdCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.containerLightGray30.of(context),
        ),
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  showPaidAppInfoDialog(context);
                },
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.star, color: Colors.amber, size: 48),
                      SizedBox(height: 12),
                      Text(
                        "유료 앱으로 업그레이드!",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "단 한 번 결제로 더 많은 혜택을 누려보세요.",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 페이지 인디케이터
            _buildPageIndicator(context, 1, totalAds),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAdCard(BuildContext context, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.2,
          ), // 옅은 회색 테두리
        ),
        child: Stack(
          children: [
            const NativeAdWidget(),
            _buildPageIndicator(context, index + 1, totalAds),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context, int page, int total) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "$page/$total",
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  void _onPageChanged(int idx) {
    setState(() => _currentPage = idx);
    if (idx == totalAds) {
      Future.microtask(() {
        _pageController.jumpToPage(0);
      });
    }
    if (idx < 0) {
      Future.microtask(() {
        _pageController.jumpToPage(totalAds - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SizedBox(
        height: 140,
        child: PageView.builder(
          controller: _pageController,
          itemCount: totalAds,
          onPageChanged: (idx) {
            if (idx == totalAds) {
              // 10페이지에서 넘기면 1페이지로 순환
              _pageController.jumpToPage(0);
            } else {
              setState(() => _currentPage = idx);
            }
          },
          itemBuilder: (context, idx) {
            if (idx == 0) {
              return _buildCustomAdCard(context);
            } else {
              return _buildNativeAdCard(context, idx);
            }
          },
        ),
      ),
    );
  }
}
