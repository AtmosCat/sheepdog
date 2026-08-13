import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/monthly_subscription/widgets/calendar_subscription_card.dart';
import 'package:sheepdog/ui/pages/subscription_detail/subscription_detail_page.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

class MonthlySubscriptionDetailPage extends StatefulWidget {
  const MonthlySubscriptionDetailPage({Key? key}) : super(key: key);

  @override
  State<MonthlySubscriptionDetailPage> createState() =>
      _MonthlySubscriptionDetailPageState();
}

class _MonthlySubscriptionDetailPageState
    extends State<MonthlySubscriptionDetailPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  List<SubscriptionService> _allSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final repo = SubscriptionServiceRepository();
    final subs = await repo.getAllServices();
    setState(() {
      _allSubscriptions = subs;
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
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  int _subscriptionCountOn(DateTime date) {
    return _allSubscriptions.where((s) {
      if (s.paymentDate == null || s.paymentCycle == null) return false;
      if (date.isBefore(s.paymentStartDate)) return false;
      if (s.paymentCycle == PaymentCycle.weekly) {
        return date.weekday == s.paymentDate!.weekday;
      } else if (s.paymentCycle == PaymentCycle.yearly) {
        if (date.month != s.paymentDate!.month) return false;
        final lastDay = DateTime(date.year, date.month + 1, 0).day;
        final day = s.paymentDate!.day > lastDay ? lastDay : s.paymentDate!.day;
        return date.day == day;
      } else if (s.paymentCycle == PaymentCycle.monthly) {
        final paymentDate = resolveServiceMonthlyDate(s, date.year, date.month);
        return date.day == paymentDate.day;
      }
      return false;
    }).length;
  }

  void _onMonthChanged(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
        1,
      );
      _selectedDate = null;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      if (_selectedDate != null &&
          _selectedDate!.day == date.day &&
          _selectedDate!.month == date.month &&
          _selectedDate!.year == date.year) {
        _selectedDate = null;
      } else {
        _selectedDate = date;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday;
    final weekDays = ['일', '월', '화', '수', '목', '금', '토'];

    // 월 전체 카드 리스트 (결제완료/예정 섹션은 월 기준)
    final allCardItems = getCalendarCardItems(_allSubscriptions, _focusedMonth)
        .where((item) => !item.date.isBefore(item.service.paymentStartDate))
        .toList();

    // 결제 완료/예정 집계 (월 기준)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final paidItems = allCardItems
        .where((e) => e.date.isBefore(today))
        .toList();
    final upcomingItems = allCardItems
        .where((e) => !e.date.isBefore(today))
        .toList();
    final paidAmount = sumSubscriptionPaymentAmounts(
      paidItems.map((e) => e.service),
    );
    final paidServices = paidItems.map((e) => e.service.name).toSet();
    final paidCount = paidItems.length;

    final upcomingAmount = sumSubscriptionPaymentAmounts(
      upcomingItems.map((e) => e.service),
    );
    final upcomingServices = upcomingItems.map((e) => e.service.name).toSet();
    final upcomingCount = upcomingItems.length;

    // 하단 리스트: 날짜 선택 시 해당 날짜만, 아니면 월 전체
    List<_CardItem> cardItems;
    if (_selectedDate != null) {
      cardItems = [];
      for (final s in _allSubscriptions) {
        final dates = getPaymentDatesInMonth(s, _focusedMonth);
        for (final d in dates) {
          if (d.year == _selectedDate!.year &&
              d.month == _selectedDate!.month &&
              d.day == _selectedDate!.day) {
            cardItems.add(_CardItem(service: s, date: d));
          }
        }
      }
      cardItems.sort((a, b) => a.date.compareTo(b.date));
    } else {
      cardItems = allCardItems;
    }

    final currencyFormat = NumberFormat('#,###원', 'ko_KR');
    final displayText = _selectedDate == null
        ? '<${_focusedMonth.month}월> 총 ${currencyFormat.format(sumSubscriptionPaymentAmounts(cardItems.map((e) => e.service)))} ・ ${cardItems.length}건'
        : '<${_selectedDate!.month}월 ${_selectedDate!.day}일> 총 ${currencyFormat.format(sumSubscriptionPaymentAmounts(cardItems.map((e) => e.service)))} ・ ${cardItems.length}건';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.containerWhite.of(context),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '구독 달력',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      backgroundColor: AppColor.containerWhite.of(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 70),
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColor.primaryGreen
                                .of(context)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColor.primaryGreen.of(context),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '결제 완료',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${currencyFormat.format(paidAmount)} ・ $paidCount건',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColor.deepBlack.of(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                paidServices.join(', '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColor.gray30.of(context),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 70),
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: AppColor.primaryRed
                                .of(context)
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_filled,
                                    color: AppColor.primaryRed.of(context),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '결제 예정',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${currencyFormat.format(upcomingAmount)} ・ $upcomingCount건',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColor.deepBlack.of(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                upcomingServices.join(', '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColor.gray30.of(context),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 달력
              Container(
                margin: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: AppColor.containerLightGray30.of(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _onMonthChanged(-1),
                          ),
                          Text(
                            '${_focusedMonth.year}.${_focusedMonth.month.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _onMonthChanged(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: weekDays
                            .map(
                              (d) => Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 2),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 0,
                              childAspectRatio:
                                  0.9, // 기존 1.2 → 0.85 등으로 줄여 셀 높이 확보
                            ),
                        itemCount: daysInMonth + firstWeekday,
                        itemBuilder: (context, idx) {
                          if (idx < firstWeekday) {
                            return const SizedBox.shrink();
                          }
                          final day = idx - firstWeekday + 1;
                          final date = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month,
                            day,
                          );
                          final isToday =
                              date.year == now.year &&
                              date.month == now.month &&
                              date.day == now.day;
                          final isSelected =
                              _selectedDate != null &&
                              _selectedDate!.day == day &&
                              _selectedDate!.month == _focusedMonth.month &&
                              _selectedDate!.year == _focusedMonth.year;
                          final hasSubscription =
                              _subscriptionCountOn(date) > 0;

                          return GestureDetector(
                            onTap: () => _onDateSelected(date),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColor.primaryBlue
                                          .of(context)
                                          .withOpacity(0.12)
                                    : Colors.transparent,
                                border: isSelected
                                    ? Border.all(
                                        color: AppColor.primaryBlue.of(context),
                                        width: 2,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$day',
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: isSelected
                                              ? AppColor.primaryBlue.of(context)
                                              : Colors.black,
                                          fontSize: 15,
                                        ),
                                      ),
                                      hasSubscription
                                          ? Container(
                                              width: 5,
                                              height: 5,
                                              margin: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColor.mainYellow.of(
                                                  context,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            )
                                          : const SizedBox(height: 6),
                                    ],
                                  ),
                                  if (isToday)
                                    Positioned(
                                      top: -1,
                                      child: Text(
                                        "오늘",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8.5
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // 구독 리스트 텍스트
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColor.gray30.of(context),
                    ),
                  ),
                ),
              ),
              // 하단 카드 리스트 (스크롤 없음)
              ...cardItems.isEmpty
                  ? [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            _selectedDate != null
                                ? '선택된 날짜에 등록된 구독이 없습니다.'
                                : '해당 월에 등록된 구독이 없습니다.',
                            style: TextStyle(
                              color: AppColor.gray30.of(context),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : cardItems.map((item) {
                      return FutureBuilder<SubscriptionCategory?>(
                        future: SubscriptionCategoryRepository()
                            .getCategoryById(item.service.categoryId),
                        builder: (context, snapshot) {
                          final cat = snapshot.data;
                          return CalendarSubscriptionCard(
                            emoji: item.service.emoji,
                            name: item.service.name,
                            categoryName: cat?.name ?? '',
                            categoryColor: cat?.colorValue ?? 0xFFF5F5F5,
                            paymentAmount: item.service.paymentAmount,
                            isAmountUndetermined:
                                serviceIsAmountUndetermined(item.service),
                            paymentCycleText: cycleToText(
                              item.service.paymentCycle,
                            ),
                            paymentDateText: paymentDateText(item.service),
                            paymentDate: item.date,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubscriptionDetailPage(
                                    subscriptionId: item.service.id,
                                  ),
                                ),
                              );
                              await _loadSubscriptions();
                            },
                          );
                        },
                      );
                    }).toList(),
              const SizedBox(height: 32), // 리스트 하단 여백
            ],
          ),
        ),
      ),
    );
  }
}

class _CardItem {
  final SubscriptionService service;
  final DateTime date;
  _CardItem({required this.service, required this.date});
}
