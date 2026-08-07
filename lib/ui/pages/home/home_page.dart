import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/data/viewmodel/user_info_viewmodel.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/ads/subscription_native_ad_card.dart';
import 'package:sheepdog/ui/pages/widgets/free_app_limit_button.dart';
import 'package:sheepdog/ui/pages/widgets/main_bottom_navigation_bar.dart';
import 'package:sheepdog/ui/pages/subscription_add/subscription_add_page.dart';
import 'package:sheepdog/ui/pages/subscription_detail/subscription_detail_page.dart';
import 'package:sheepdog/ui/pages/subscription_management/subscription_management_page.dart';
import 'package:sheepdog/ui/pages/widgets/subscription_card.dart';
import 'package:sheepdog/ui/utils/fcm_utils.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  List<SubscriptionService> _subscriptionList = [];
  List<SubscriptionService> _upcomingList = [];

  @override
  void initState() {
    super.initState();
    FCMUtils().initFCM(requestPermission: false);
    FCMUtils().setupInteractedMessage(context);
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final repo = SubscriptionServiceRepository();
    final data = await repo.getAllServices();

    final upcoming = <MapEntry<SubscriptionService, DateTime>>[];
    for (final sub in data) {
      if (sub.paymentDate == null || sub.paymentCycle == null) continue;
      final dates = getFutureDdays(sub);
      if (dates.isEmpty) continue;
      upcoming.add(MapEntry(sub, dates.first));
    }

    upcoming.sort((a, b) => a.value.compareTo(b.value));
    final sortedUpcoming = upcoming.map((e) => e.key).take(10).toList();

    if (!mounted) return;
    setState(() {
      _subscriptionList = data;
      _upcomingList = sortedUpcoming;
    });
  }

  List<_CardItem> getCalendarCardItems(
    List<SubscriptionService> services,
    DateTime month,
  ) {
    final List<_CardItem> items = [];
    for (final s in services) {
      final dates = getPaymentDatesInMonth(s, month);
      for (final d in dates) {
        items.add(_CardItem(service: s, date: d));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = now.month;
    final today = DateTime(now.year, now.month, now.day);
    final currencyFormat = NumberFormat('#,###원', 'ko_KR');
    final isPremium =
        Provider.of<UserInfoViewModel>(context).userInfo?.isPremium ?? false;
    final cardItems = getCalendarCardItems(_subscriptionList, now);

    final thisMonthTotalAmount = sumSubscriptionPaymentAmounts(
      cardItems.map((e) => e.service),
    );
    final thisMonthTotalCount = cardItems.length;

    final paidItems = cardItems.where((e) => e.date.isBefore(today)).toList();
    final thisMonthPaidAmount = sumSubscriptionPaymentAmounts(
      paidItems.map((e) => e.service),
    );
    final thisMonthPaidCount = paidItems.length;

    final upcomingItems =
        cardItems.where((e) => !e.date.isBefore(today)).toList();
    final thisMonthUpcomingAmount = sumSubscriptionPaymentAmounts(
      upcomingItems.map((e) => e.service),
    );
    final thisMonthUpcomingCount = upcomingItems.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.containerWhite.of(context),
        title: const Text('홈'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: AppColor.containerWhite.of(context),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.calendar_today,
                        color: AppColor.deepBlack.of(context),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '이달의 구독',
                        style: TextStyle(
                          color: AppColor.defaultBlack.of(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColor.containerLightGray30.of(context),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 68,
                                height: 68,
                                child: CircularProgressIndicator(
                                  value: thisMonthTotalAmount == 0
                                      ? 0
                                      : thisMonthPaidAmount /
                                          thisMonthTotalAmount,
                                  strokeWidth: 7,
                                  backgroundColor:
                                      AppColor.mainYellowLight2.of(context),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColor.mainYellow.of(context),
                                  ),
                                ),
                              ),
                              Text(
                                '$month월',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: AppColor.deepBlack.of(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${currencyFormat.format(thisMonthTotalAmount)} ・ ${thisMonthTotalCount}건',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColor.deepBlack.of(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColor.primaryGreen.of(context),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '결제 완료: ${currencyFormat.format(thisMonthPaidAmount)} ・ ${thisMonthPaidCount}건',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColor.gray30.of(context),
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_filled,
                                      color: AppColor.primaryRed.of(context),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '결제 예정: ${currencyFormat.format(thisMonthUpcomingAmount)} ・ ${thisMonthUpcomingCount}건',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColor.gray30.of(context),
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: AppColor.defaultBlack.of(context),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '결제가 임박한 구독',
                        style: TextStyle(
                          color: AppColor.defaultBlack.of(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SubscriptionManagementPage(),
                            ),
                          );
                          if (mounted) await _loadSubscriptions();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '더보기',
                              style: TextStyle(
                                color: AppColor.gray20.of(context),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColor.gray20.of(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _upcomingList.isEmpty
                      ? Column(
                          children: [
                            if (!isPremium) const SubscriptionNativeAdCard(),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  '결제가 임박한 구독이 없습니다.',
                                  style: TextStyle(
                                    color: AppColor.gray30.of(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < _upcomingList.length; i++) ...[
                              FutureBuilder<SubscriptionCategory?>(
                                future: SubscriptionCategoryRepository()
                                    .getCategoryById(_upcomingList[i].categoryId),
                                builder: (context, snapshot) {
                                  final item = _upcomingList[i];
                                  final category = snapshot.data;
                                  return SubscriptionCard(
                                    emoji: item.emoji,
                                    name: item.name,
                                    categoryName: category?.name ?? '',
                                    categoryColor:
                                        category?.colorValue ?? 0xFFF5F5F5,
                                    paymentAmount: item.paymentAmount,
                                    isAmountUndetermined:
                                        serviceIsAmountUndetermined(item),
                                    paymentCycleText: cycleToText(
                                      item.paymentCycle,
                                    ),
                                    paymentDateText: paymentDateText(item),
                                    dDay: getServiceDDay(item),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SubscriptionDetailPage(
                                            subscriptionId: item.id,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        await _loadSubscriptions();
                                      }
                                    },
                                  );
                                },
                              ),
                              if (i == 0 && !isPremium)
                                const SubscriptionNativeAdCard(),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 200),
              ],
            ),
            FreeAppLimitButton(
              currentCount: _subscriptionList.length,
              onAdd: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionAddPage(),
                  ),
                );
                if (result == true) {
                  await _loadSubscriptions();
                }
              },
              parentContext: context,
            ),
          ],
        ),
      ),
      bottomNavigationBar: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: MainBottomNavigationBar(selectedIndex: 0),
      ),
    );
  }
}

class _CardItem {
  final SubscriptionService service;
  final DateTime date;
  _CardItem({required this.service, required this.date});
}
