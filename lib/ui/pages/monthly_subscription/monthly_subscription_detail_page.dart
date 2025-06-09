import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/subscription_detail/subscription_detail_page.dart';
import 'package:sheepdog/ui/pages/widgets/subscription_card.dart';
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

    final currencyFormat = NumberFormat('#,###원', 'ko_KR');
    int totalAmount;
    int totalCount;
    String displayText;

    if (_selectedDate == null) {
      // 월 전체
      totalAmount = _filteredSubscriptions.fold(
        0,
        (sum, s) => sum + (s.paymentAmount ?? 0),
      );
      totalCount = _filteredSubscriptions.length;
      displayText =
          '${_focusedMonth.month}월의 구독 : 총 ${currencyFormat.format(totalAmount)} ・ $totalCount건';
    } else {
      // 특정 날짜
      totalAmount = _filteredSubscriptions.fold(
        0,
        (sum, s) => sum + (s.paymentAmount ?? 0),
      );
      totalCount = _filteredSubscriptions.length;
      displayText =
          '${_selectedDate!.month}월 ${_selectedDate!.day}일의 구독 : 총 ${currencyFormat.format(totalAmount)} ・ $totalCount건';
    }

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
                displayText,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
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
                    separatorBuilder: (_, __) => const SizedBox(height: 0),
                    itemBuilder: (context, idx) {
                      final item = _filteredSubscriptions[idx];
                      return FutureBuilder<SubscriptionCategory?>(
                        future: SubscriptionCategoryRepository()
                            .getCategoryById(item.categoryId),
                        builder: (context, snapshot) {
                          final cat = snapshot.data;
                          return SubscriptionCard(
                            emoji: item.emoji,
                            name: item.name,
                            categoryName: cat?.name ?? '',
                            categoryColor: cat?.colorValue ?? 0xFFF5F5F5,
                            paymentAmount: item.paymentAmount,
                            paymentCycleText: cycleToText(item.paymentCycle),
                            paymentDateText: paymentDateText(item),
                            dDay: getDDay(item.paymentDate, item.paymentCycle),
                            onTap: () async {
                              final category =
                                  await SubscriptionCategoryRepository()
                                      .getCategoryById(item.categoryId);
                              final paymentMethod =
                                  await PaymentMethodRepository().getMethodById(
                                    item.paymentMethodId,
                                  );

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubscriptionDetailPage(
                                    service: item,
                                    category: category, // null 가능
                                    paymentMethod: paymentMethod, // null 가능
                                  ),
                                ),
                              );
                              await _loadSubscriptions();
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
