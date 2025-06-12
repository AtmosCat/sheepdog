import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'package:sheepdog/ui/pages/mypage/my_page.dart';
import 'package:sheepdog/ui/pages/subscription_management/subscription_management_page.dart';

class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({
    super.key,
    required int selectedIndex,
  }) : _selectedIndex = selectedIndex;

  final int _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (_selectedIndex == index) return; // 이미 선택된 탭이면 아무 동작 안 함
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
                builder: (_) => const SubscriptionManagementPage(),
              ),
            );
            break;
          case 2:
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
          icon: Icon(CupertinoIcons.creditcard_fill),
          label: '구독 관리',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: '마이페이지',
        ),
      ],
    );
  }
}