import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/subscription_detail/subscription_detail_page.dart';

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
  List<SubscriptionService> _filteredSubscriptions = [];

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
      _filterSubscriptions();
    });
  }

  void _filterSubscriptions() {
    setState(() {
      if (_selectedDate != null) {
        // 날짜 선택 시 해당 날짜 결제만
        _filteredSubscriptions = _allSubscriptions
            .where(
              (s) =>
                  s.paymentDate != null &&
                  s.paymentDate!.year == _focusedMonth.year &&
                  s.paymentDate!.month == _focusedMonth.month &&
                  s.paymentDate!.day == _selectedDate!.day,
            )
            .toList();
      } else {
        // 월 전체 구독
        _filteredSubscriptions = _allSubscriptions
            .where(
              (s) =>
                  s.paymentDate != null &&
                  s.paymentDate!.year == _focusedMonth.year &&
                  s.paymentDate!.month == _focusedMonth.month,
            )
            .toList();
      }
      // 디데이 임박순 정렬(옵션)
      _filteredSubscriptions.sort(
        (a, b) => a.paymentDate!.compareTo(b.paymentDate!),
      );
    });
  }

  void _onMonthChanged(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
        1,
      );
      _selectedDate = null;
      _filterSubscriptions();
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      if (_selectedDate != null &&
          _selectedDate!.day == date.day &&
          _selectedDate!.month == date.month &&
          _selectedDate!.year == date.year) {
        _selectedDate = null; // 선택 해제
      } else {
        _selectedDate = date;
      }
      _filterSubscriptions();
    });
  }

  // 각 날짜에 구독 개수
  int _subscriptionCountOn(DateTime date) {
    return _allSubscriptions
        .where(
          (s) =>
              s.paymentDate != null &&
              s.paymentDate!.year == date.year &&
              s.paymentDate!.month == date.month &&
              s.paymentDate!.day == date.day,
        )
        .length;
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
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.containerWhite.of(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColor.deepBlack.of(context),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '이달의 구독',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      backgroundColor: AppColor.containerWhite.of(context),
      body: Column(
        children: [
          // 달력
          Container(
            margin: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: AppColor.containerLightGray30.of(context),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                  // 요일 헤더
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
                  // 달력 날짜
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 0,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: daysInMonth + (firstWeekday - 1),
                    itemBuilder: (context, idx) {
                      if (idx < firstWeekday - 1) {
                        return const SizedBox.shrink();
                      }
                      final day = idx - (firstWeekday - 2);
                      final date = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month,
                        day,
                      );
                      final isSelected =
                          _selectedDate != null &&
                          _selectedDate!.day == day &&
                          _selectedDate!.month == _focusedMonth.month &&
                          _selectedDate!.year == _focusedMonth.year;
                      final count = _subscriptionCountOn(date);

                      return GestureDetector(
                        onTap: () => _onDateSelected(date),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColor.mainYellow.of(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: isSelected
                                      ? AppColor.deepBlack.of(context)
                                      : Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // 구독 개수만큼 점 표시
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  count,
                                  (i) => Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor.mainYellow.of(context),
                                      shape: BoxShape.circle,
                                    ),
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
          const SizedBox(height: 10),
          // 구독 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_focusedMonth.month}월의 구독 목록',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredSubscriptions.isEmpty
                ? Center(
                    child: Text(
                      _selectedDate != null
                          ? '선택된 날짜에 등록된 구독이 없습니다.'
                          : '해당 월에 등록된 구독이 없습니다.',
                      style: TextStyle(
                        color: AppColor.gray30.of(context),
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    itemCount: _filteredSubscriptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final item = _filteredSubscriptions[idx];
                      return GestureDetector(
                        onTap: () async {
                          final category =
                              await SubscriptionCategoryRepository()
                                  .getCategoryById(item.categoryId);
                          final paymentMethod = await PaymentMethodRepository()
                              .getMethodById(item.paymentMethodId);
                          if (category != null && paymentMethod != null) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubscriptionDetailPage(
                                  service: item,
                                  category: category,
                                  paymentMethod: paymentMethod,
                                ),
                              ),
                            );
                            // 필요시 돌아와서 새로고침
                            await _loadSubscriptions();
                          }
                        },
                        child: FutureBuilder<SubscriptionCategory?>(
                          future: SubscriptionCategoryRepository()
                              .getCategoryById(item.categoryId),
                          builder: (context, snapshot) {
                            final cat = snapshot.data;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 이모지 (흰색 원형 + 내부 패딩)
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Center(
                                        child: Text(
                                          item.emoji ?? '💬',
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // 서비스명, 카테고리, 금액/주기/결제일
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Color(
                                                  cat?.colorValue ?? 0xFFF5F5F5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                              child: Text(
                                                cat?.name ?? '',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${NumberFormat('#,###원', 'ko_KR').format(item.paymentAmount ?? 0)} ・ ${_cycleToText(item.paymentCycle)} ${_paymentDateText(item)}',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // D-day
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'D-${getDDay(item.paymentDate, item.paymentCycle)}',
                                        style: TextStyle(
                                          color: AppColor.primaryRed.of(
                                            context,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      // 결제일 날짜 텍스트가 필요하다면 아래 주석 해제
                                      // Text(
                                      //   item.paymentDate != null
                                      //       ? DateFormat('yyyy-MM-dd').format(item.paymentDate!)
                                      //       : '',
                                      //   style: TextStyle(
                                      //     color: AppColor.gray30.of(context),
                                      //     fontSize: 12,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _cycleToText(PaymentCycle? cycle) {
  switch (cycle) {
    case PaymentCycle.yearly:
      return '매년';
    case PaymentCycle.monthly:
      return '매월';
    case PaymentCycle.weekly:
      return '매주';
    default:
      return '';
  }
}

// 결제일 텍스트 변환 함수 예시
String _paymentDateText(SubscriptionService item) {
  if (item.paymentCycle == PaymentCycle.yearly && item.paymentDate != null) {
    return '${item.paymentDate!.month}월 ${item.paymentDate!.day}일';
  }
  if (item.paymentCycle == PaymentCycle.monthly && item.paymentDate != null) {
    return '${item.paymentDate!.day}일';
  }
  if (item.paymentCycle == PaymentCycle.weekly && item.paymentDate != null) {
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekDays[item.paymentDate!.weekday - 1] + '요일';
  }
  return '';
}

int getDDay(DateTime? paymentDate, PaymentCycle? paymentCycle) {
  if (paymentDate == null || paymentCycle == null) return 9999;
  final now = DateTime.now();
  final nowDate = DateTime(now.year, now.month, now.day);
  final payDate = DateTime(
    paymentDate.year,
    paymentDate.month,
    paymentDate.day,
  );
  final diff = payDate.difference(nowDate).inDays;
  if (diff >= 0) return diff;

  // 결제일이 지났으면 다음 결제일까지 남은 일수 계산
  if (paymentCycle == PaymentCycle.monthly) {
    // 다음 달 결제일
    int nextMonth = payDate.month + 1;
    int nextYear = payDate.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }
    DateTime nextPayDate;
    try {
      nextPayDate = DateTime(nextYear, nextMonth, payDate.day);
    } catch (_) {
      // 2월 등 없는 날짜 보정
      final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
      nextPayDate = DateTime(nextYear, nextMonth, lastDay);
    }
    return nextPayDate.difference(nowDate).inDays;
  } else if (paymentCycle == PaymentCycle.yearly) {
    // 다음 해 결제일
    int nextYear = payDate.year + 1;
    DateTime nextPayDate;
    try {
      nextPayDate = DateTime(nextYear, payDate.month, payDate.day);
    } catch (_) {
      final lastDay = DateTime(nextYear, payDate.month + 1, 0).day;
      nextPayDate = DateTime(nextYear, payDate.month, lastDay);
    }
    return nextPayDate.difference(nowDate).inDays;
  } else if (paymentCycle == PaymentCycle.weekly) {
    // 다음 주 같은 요일
    int currentWeekday = nowDate.weekday; // 1(월)~7(일)
    int payWeekday = payDate.weekday;
    int daysUntilNext = (payWeekday - currentWeekday) % 7;
    if (daysUntilNext <= 0) daysUntilNext += 7;
    return daysUntilNext;
  }
  return 9999;
}
