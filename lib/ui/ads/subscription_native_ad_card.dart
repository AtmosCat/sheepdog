import 'package:flutter/material.dart';
import 'package:sheepdog/ui/ads/native_ad_widget.dart';

/// 구독 카드와 동일한 여백·모서리로 네이티브 광고를 표시합니다.
class SubscriptionNativeAdCard extends StatelessWidget {
  const SubscriptionNativeAdCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: const NativeAdWidget(height: 72),
    );
  }
}
