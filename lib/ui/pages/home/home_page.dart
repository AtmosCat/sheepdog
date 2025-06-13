import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/widgets/free_app_limit_button.dart';
import 'package:sheepdog/ui/pages/widgets/main_bottom_navigation_bar.dart';
import 'package:sheepdog/ui/pages/subscription_add/subscription_add_page.dart';
import 'package:sheepdog/ui/pages/subscription_detail/subscription_detail_page.dart';
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
    // 알림 설정
    FCMUtils().initFCM();
    FCMUtils().setupInteractedMessage(context);
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final repo = SubscriptionServiceRepository();
    final data = await repo.getAllServices();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // D-3 이내 임박 구독 필터링
    final upcoming = <SubscriptionService>[];
    for (final sub in data) {
      final dates = getFuturePaymentDates(sub, maxCount: 1);
      if (dates.isEmpty) continue;
      final paymentDate = dates.first;
      final dDay = paymentDate.difference(today).inDays;
      if (dDay >= 0 && dDay <= 3) {
        upcoming.add(sub);
      }
    }

    setState(() {
      _subscriptionList = data;
      _upcomingList = upcoming;
    });
  }

  // 실제 결제 발생일 리스트 (주기별, 시작일 이후만)
  List<DateTime> getPaymentDatesInMonth(
    SubscriptionService service,
    DateTime month,
  ) {
    final List<DateTime> dates = [];
    if (service.paymentDate == null || service.paymentCycle == null)
      return dates;
    final startDate = service.paymentStartDate;

    if (service.paymentCycle == PaymentCycle.monthly) {
      final day = service.paymentDate!.day;
      if (DateTime(month.year, month.month, day).isAfter(startDate) ||
          DateTime(month.year, month.month, day).isAtSameMomentAs(startDate)) {
        dates.add(DateTime(month.year, month.month, day));
      }
    } else if (service.paymentCycle == PaymentCycle.weekly) {
      final weekday = service.paymentDate!.weekday;
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      for (int d = 1; d <= lastDay; d++) {
        final date = DateTime(month.year, month.month, d);
        if (date.weekday == weekday && !date.isBefore(startDate)) {
          dates.add(date);
        }
      }
    } else if (service.paymentCycle == PaymentCycle.yearly) {
      if (service.paymentDate!.month == month.month) {
        final day = service.paymentDate!.day;
        if (DateTime(month.year, month.month, day).isAfter(startDate) ||
            DateTime(
              month.year,
              month.month,
              day,
            ).isAtSameMomentAs(startDate)) {
          dates.add(DateTime(month.year, month.month, day));
        }
      }
    }
    return dates;
  }

  // 카드 아이템 생성 (결제 발생일별)
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

    // 실제 결제 발생일별 카드 아이템
    final cardItems = getCalendarCardItems(_subscriptionList, now);

    final thisMonthTotalAmount = cardItems.fold(
      0,
      (sum, e) => sum + (e.service.paymentAmount ?? 0),
    );
    final thisMonthTotalCount = cardItems.length;

    // 결제 완료: 결제일이 오늘 이전
    final paidItems = cardItems.where((e) => e.date.isBefore(today)).toList();
    final thisMonthPaidAmount = paidItems.fold(
      0,
      (sum, e) => sum + (e.service.paymentAmount ?? 0),
    );
    final thisMonthPaidCount = paidItems.length;

    // 결제 예정: 결제일이 오늘이거나 이후
    final upcomingItems = cardItems
        .where((e) => !e.date.isBefore(today))
        .toList();
    final thisMonthUpcomingAmount = upcomingItems.fold(
      0,
      (sum, e) => sum + (e.service.paymentAmount ?? 0),
    );
    final thisMonthUpcomingCount = upcomingItems.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.containerWhite.of(context),
        title: Text('홈'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: AppColor.containerWhite.of(context),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'lib/assets/icons/icon10.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '구독 관리를 쉽게,\n쉽독이 도와드릴게요!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColor.deepBlack.of(context),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
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
                                  backgroundColor: AppColor.mainYellowLight2.of(
                                    context,
                                  ),
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

                // 결제 임박 리스트
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
                        '3일 내 결제',
                        style: TextStyle(
                          color: AppColor.defaultBlack.of(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '총 ${_upcomingList.length}건',
                        style: TextStyle(
                          color: AppColor.gray20.of(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 결제 임박 카드 리스트 (옅은 회색 배경, 카드 형식)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _upcomingList.isEmpty
                      ? Padding(
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
                        )
                      : Column(
                          children: _upcomingList.map((item) {
                            return FutureBuilder<SubscriptionCategory?>(
                              future: SubscriptionCategoryRepository()
                                  .getCategoryById(item.categoryId),
                              builder: (context, snapshot) {
                                final category = snapshot.data;
                                return SubscriptionCard(
                                  emoji: item.emoji,
                                  name: item.name,
                                  categoryName:
                                      category?.name ?? '', // 없으면 빈 문자열
                                  categoryColor:
                                      category?.colorValue ?? 0xFFF5F5F5,
                                  paymentAmount: item.paymentAmount,
                                  paymentCycleText: cycleToText(
                                    item.paymentCycle,
                                  ),
                                  paymentDateText: paymentDateText(item),
                                  dDay: getDDay(
                                    item.paymentDate!,
                                    item.paymentCycle!,
                                    item.paymentStartDate,
                                  ),
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
                            );
                          }).toList(),
                        ),
                ),

                SizedBox(height: 200),
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
      bottomNavigationBar: MainBottomNavigationBar(selectedIndex: 0),
    );
  }
}

class _CardItem {
  final SubscriptionService service;
  final DateTime date;
  _CardItem({required this.service, required this.date});
}
