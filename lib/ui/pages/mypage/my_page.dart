import 'package:flutter/material.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'package:sheepdog/ui/pages/mypage/category_management_page.dart';
import 'package:sheepdog/ui/pages/mypage/notification_history_page.dart';
import 'package:sheepdog/ui/pages/mypage/notification_settings_page.dart';
import 'package:sheepdog/ui/pages/mypage/paid_app_info_page.dart';
import 'package:sheepdog/ui/pages/mypage/payment_methods_page.dart';
import 'package:sheepdog/ui/pages/subscription_management/subscription_management_page.dart';

class MyPage extends StatelessWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.containerWhite.of(context),
      appBar: AppBar(title: const Text('마이페이지'), centerTitle: true),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              Icons.notifications,
              color: AppColor.defaultBlack.of(context),
            ),
            title: Text(
              '알림 설정',
              style: TextStyle(color: AppColor.defaultBlack.of(context)),
            ),
            onTap: () {
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
              Icons.history,
              color: AppColor.defaultBlack.of(context),
            ),
            title: Text(
              '알림 전송 내역',
              style: TextStyle(color: AppColor.defaultBlack.of(context)),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationHistoryPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.payment,
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
              Icons.info_outline,
              color: AppColor.defaultBlack.of(context),
            ),
            title: Text(
              '유료 앱 안내',
              style: TextStyle(color: AppColor.defaultBlack.of(context)),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaidAppInfoPage()),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SubscriptionManagementPage(),
              ),
            );
          }
        },
        backgroundColor: AppColor.containerWhite.of(context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColor.mainYellow.of(context),
        unselectedItemColor: AppColor.gray20.of(context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions_rounded),
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
