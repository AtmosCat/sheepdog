import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sheepdog/theme/colors.dart';

class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({
    super.key,
    required int selectedIndex,
    required this.onTap,
  }) : _selectedIndex = selectedIndex;

  final int _selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: onTap,
        backgroundColor: AppColor.containerWhite.of(context),
        type: BottomNavigationBarType.fixed,
        iconSize: 24,
        selectedItemColor: AppColor.mainYellow.of(context),
        unselectedItemColor: AppColor.gray20.of(context),
        selectedFontSize: 12,
        unselectedFontSize: 12,
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
    );
  }
}
