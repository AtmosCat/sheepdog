import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/ads/banner_ad_widget.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'package:sheepdog/ui/pages/monthly_subscription/monthly_subscription_detail_page.dart';
import 'package:sheepdog/ui/pages/mypage/my_page.dart';
import 'package:sheepdog/ui/pages/subscription_management/subscription_management_page.dart';

class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({super.key, required int selectedIndex})
    : _selectedIndex = selectedIndex;

  final int _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (_selectedIndex == index) return;
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MonthlySubscriptionDetailPage(),
                  ),
                );
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionManagementPage(),
                  ),
                );
                break;
              case 3:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPage()),
                );
                break;
            }
          },
          backgroundColor: AppColor.containerWhite.of(context),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColor.mainYellow.of(context),
          unselectedItemColor: AppColor.gray20.of(context),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar_today),
              label: '구독 달력',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.creditcard_fill),
              label: '구독 관리',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: '마이페이지',
            ),
          ],
        ),
        // 배너 광고 추가
        const BannerAdWidget(),
      ],
    );
  }
}
