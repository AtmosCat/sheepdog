import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/core/premium/premium_config.dart';
import 'package:sheepdog/data/premium/premium_controller.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/mypage/notice_list_page.dart';
import 'package:sheepdog/ui/pages/mypage/category_management_page.dart';
import 'package:sheepdog/ui/pages/mypage/notification_settings_page.dart';
import 'package:sheepdog/ui/pages/mypage/payment_methods_page.dart';
import 'package:sheepdog/ui/pages/premium/premium_gate.dart';

class MyPage extends StatelessWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.containerWhite.of(context),
      appBar: AppBar(title: const Text('마이페이지'), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SheepdogProSettingsCard(),
          ),
          ListTile(
            leading: Icon(
              Icons.notifications,
              color: AppColor.defaultBlack.of(context),
            ),
            title: Text(
              '결제일 알림 설정',
              style: TextStyle(color: AppColor.defaultBlack.of(context)),
            ),
            onTap: () {
              if (gateSheepdogPro(context)) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.credit_card,
              color: AppColor.defaultBlack.of(context),
            ),
            title: Text(
              '결제 수단 관리',
              style: TextStyle(color: AppColor.defaultBlack.of(context)),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.category,
              color: AppColor.defaultBlack.of(context),
            ),
            title: Text(
              '카테고리 관리',
              style: TextStyle(color: AppColor.defaultBlack.of(context)),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.campaign,
              color: AppColor.defaultBlack.of(context),
            ),
            title: Text(
              '공지사항',
              style: TextStyle(color: AppColor.defaultBlack.of(context)),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NoticeListPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SheepdogProSettingsCard extends StatefulWidget {
  const _SheepdogProSettingsCard();

  @override
  State<_SheepdogProSettingsCard> createState() =>
      _SheepdogProSettingsCardState();
}

class _SheepdogProSettingsCardState extends State<_SheepdogProSettingsCard> {
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
    final isPro = context.watch<PremiumController>().isPro;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openSheepdogPro(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF007AFF),
                Color(0xFF4DA3FF),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    PremiumConfig.iconPremium,
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '쉽독 Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (isPro) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '이용 중',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (isPro)
                        const Text(
                          '광고 제거 · 결제일 알림 · 구독 달력 · 개수 무제한',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        )
                      else
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: Text(
                            _titles[_index],
                            key: ValueKey(_index),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
