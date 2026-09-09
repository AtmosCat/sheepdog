import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/data/premium/premium_controller.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/ads/banner_ad_widget.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'package:sheepdog/ui/pages/monthly_subscription/monthly_subscription_detail_page.dart';
import 'package:sheepdog/ui/pages/mypage/my_page.dart';
import 'package:sheepdog/ui/pages/premium/premium_gate.dart';
import 'package:sheepdog/ui/pages/subscription_management/subscription_management_page.dart';
import 'package:sheepdog/ui/pages/widgets/main_bottom_navigation_bar.dart';

/// 메인 4탭을 하나의 셸에서 공유합니다.
/// - 상단 배너 구좌 1개 (탭 전환 시 재로드 없음)
/// - 탭 전환은 하단바만 (스와이프 비활성)
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  static MainShellScope? maybeOf(BuildContext context) =>
      MainShellScope.maybeOf(context);

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late final PageController _pageController;
  late int _currentIndex;
  static const _calendarTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void goToTab(int index) {
    if (index < 0 || index > 3) return;
    if (index == _calendarTabIndex &&
        !context.read<PremiumController>().isPro) {
      openSheepdogPro(context);
      return;
    }
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumController>().isPro;

    return MainShellScope(
      goToTab: goToTab,
      child: ColoredBox(
        color: AppColor.containerWhite.of(context),
        child: Column(
          children: [
            BannerAdWidget(isPremium: isPremium),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  children: const [
                    _KeepAlive(child: HomePage()),
                    _KeepAlive(child: MonthlySubscriptionDetailPage()),
                    _KeepAlive(child: SubscriptionManagementPage()),
                    _KeepAlive(child: MyPage()),
                  ],
                ),
              ),
            ),
            MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: MainBottomNavigationBar(
                selectedIndex: _currentIndex,
                onTap: goToTab,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final void Function(int index) goToTab;

  static MainShellScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => false;
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
