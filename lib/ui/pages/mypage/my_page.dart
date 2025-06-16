import 'package:flutter/material.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/mypage/widgets/show_paid_app_info_dialog.dart';
import 'package:sheepdog/ui/pages/mypage/user_info_page.dart';
import 'package:sheepdog/ui/pages/widgets/main_bottom_navigation_bar.dart';
import 'package:sheepdog/ui/pages/mypage/category_management_page.dart';
import 'package:sheepdog/ui/pages/mypage/notification_history_page.dart';
import 'package:sheepdog/ui/pages/mypage/notification_settings_page.dart';
import 'package:sheepdog/ui/pages/mypage/payment_methods_page.dart';

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
              Icons.person,
              color: AppColor.defaultBlack.of(context),
            ),
            title: Text(
              '내 정보',
              style: TextStyle(color: AppColor.defaultBlack.of(context)),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserInfoPage()),
              );
            },
          ),
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
          // ListTile(
          //   leading: Icon(
          //     Icons.history,
          //     color: AppColor.defaultBlack.of(context),
          //   ),
          //   title: Text(
          //     '알림 전송 내역',
          //     style: TextStyle(color: AppColor.defaultBlack.of(context)),
          //   ),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => const NotificationHistoryPage(),
          //       ),
          //     );
          //   },
          // ),
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
              showPaidAppInfoDialog(context);
            },
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNavigationBar(selectedIndex: 3),
    );
  }
}
