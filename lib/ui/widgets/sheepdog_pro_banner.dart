import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/core/premium/premium_config.dart';
import 'package:sheepdog/data/premium/premium_controller.dart';
import 'package:sheepdog/ui/pages/premium/premium_gate.dart';

/// 홈 / 구독 관리용 쉽독 Pro 홍보 배너.
class SheepdogProBanner extends StatefulWidget {
  const SheepdogProBanner({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 16),
  });

  final EdgeInsetsGeometry padding;

  @override
  State<SheepdogProBanner> createState() => _SheepdogProBannerState();
}

class _SheepdogProBannerState extends State<SheepdogProBanner> {
  static const _accent = Color(0xFF007AFF);
  static const _titles = [
    '쉽독 Pro 구독하고 결제일 알림 받기',
    '쉽독 Pro 구독하고 광고 제거',
    '쉽독 Pro 구독하고 구독 달력 사용하기',
    '쉽독 Pro 구독하고 구독 개수 제한 없애기',
  ];

  var _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _titles.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<PremiumController>().isPro) {
      final padding = widget.padding.resolve(Directionality.of(context));
      return SizedBox(height: padding.vertical);
    }

    return Padding(
      padding: widget.padding,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openSheepdogPro(context),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF007AFF),
                  Color(0xFF4DA3FF),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              child: Row(
                children: [
                  Image.asset(
                    PremiumConfig.iconPremium,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Text(
                        _titles[_index],
                        key: ValueKey(_index),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
