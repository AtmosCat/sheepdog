import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/subscription_add/subscription_add_page.dart';
import 'package:sheepdog/ui/pages/test_data/test_data_input_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _selectedIndex = 0;
  List<SubscriptionService> _subscriptionList = [];
  List<SubscriptionService> _upcomingList = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    // 실제 DB에서 구독 데이터 불러오기
    final repo = SubscriptionServiceRepository();
    final data = await repo.getAllServices(); // 비동기 함수라면 await 사용
    final now = DateTime.now();

    // 결제 임박 리스트: 결제일까지 3일 이내
    final upcoming = data.where((item) {
      final date = item.paymentDate; // 이미 DateTime 타입이어야 함
      if (date == null) return false;
      final diff = date.difference(now).inDays;
      return diff <= 3 && diff >= 0;
    }).toList();

    setState(() {
      _subscriptionList = data;
      _upcomingList = upcoming;
    });
  }

  String getPaymentDateDisplay(SubscriptionService item) {
    if (item.paymentCycle == PaymentCycle.yearly && item.paymentDate != null) {
      // 매년 6월 5일
      return '매년 ${item.paymentDate!.month}월 ${item.paymentDate!.day}일';
    }
    if (item.paymentCycle == PaymentCycle.monthly && item.paymentDate != null) {
      // 매월 5일 (paymentDate를 DateTime이 아니라 int(일)로 저장했다면 item.paymentDate!.day)
      return '매월 ${item.paymentDate!.day}일';
    }
    if (item.paymentCycle == PaymentCycle.weekly && item.paymentDate != null) {
      // 매주 무슨요일 (paymentDate를 요일 문자열로 저장했다면)
      // DateTime weekday: 1(월)~7(일)
      const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = item.paymentDate!.weekday; // 1~7
      return '매주 ${weekDays[weekday - 1]}요일';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = now.month;
    final currencyFormat = NumberFormat('#,###원', 'ko_KR');

    final thisMonthList = _subscriptionList.where((item) {
      final date = item.paymentDate;
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();

    final thisMonthTotalAmount = thisMonthList.fold(
      0,
      (sum, item) => sum + (item.paymentAmount ?? 0),
    );
    final thisMonthTotalCount = thisMonthList.length;

    int getDDay(DateTime? paymentDate) {
      if (paymentDate == null) return 9999;
      final nowDate = DateTime(now.year, now.month, now.day);
      final payDate = DateTime(
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
      );
      return payDate.difference(nowDate).inDays;
    }

    final thisMonthPaidCount = thisMonthList
        .where((item) => getDDay(item.paymentDate) < 0)
        .length;
    final thisMonthPaidAmount = thisMonthList
        .where((item) => getDDay(item.paymentDate) < 0)
        .fold(0, (sum, item) => sum + (item.paymentAmount ?? 0));
    final thisMonthUpcomingCount = thisMonthList
        .where((item) => getDDay(item.paymentDate) >= 0)
        .length;
    final thisMonthUpcomingAmount = thisMonthList
        .where((item) => getDDay(item.paymentDate) >= 0)
        .fold(0, (sum, item) => sum + (item.paymentAmount ?? 0));

    return Scaffold(
      backgroundColor: AppColor.containerWhite.of(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: AppColor.containerWhite.of(context),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.menu),
              color: AppColor.deepBlack.of(context),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestDataInputPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColor.mainYellow.of(context),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('lib/assets/icons/icon6.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '구독 관리를 쉽게,\n쉽독이 도와드릴게요!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColor.deepBlack.of(context),
                            height: 1.3,
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
                        Icons.calendar_today,
                        color: AppColor.deepBlack.of(context),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '이달의 구독',
                        style: TextStyle(
                          color: AppColor.deepBlack.of(context),
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
                                  value: thisMonthTotalCount == 0
                                      ? 0
                                      : thisMonthPaidCount /
                                            thisMonthTotalCount,
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
                                '${month}월',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: AppColor.mainBrown.of(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 18),
                          // Pixel Overflow 방지: Flexible로 감싸고 maxLines 제한
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
                                      Icons.check_circle_outline,
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
                                          fontWeight: FontWeight.normal
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
                                      Icons.access_time,
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
                                          fontWeight: FontWeight.normal
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
                        color: AppColor.primaryRed.of(context),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '결제 임박',
                        style: TextStyle(
                          color: AppColor.primaryRed.of(context),
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
                  child: Column(
                    children: _upcomingList.map((item) {
                      final dDay = getDDay(item.paymentDate);

                      return FutureBuilder<SubscriptionCategory?>(
                        future: SubscriptionCategoryRepository()
                            .getCategoryById(item.categoryId),
                        builder: (context, snapshot) {
                          final category = snapshot.data;
                          final categoryName = category?.name ?? '';
                          final categoryColor =
                              category?.colorValue ?? 0xFFF5F5F5;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 브랜드 이모지 (흰색 원형 + 내부 패딩)
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(categoryColor),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              categoryName,
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
                                        '${currencyFormat.format(item.paymentAmount ?? 0)} ・ ${_cycleToText(item.paymentCycle)} ${_paymentDateText(item)}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                          fontWeight: FontWeight.normal,
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
                                      dDay != null ? 'D-$dDay' : '',
                                      style: TextStyle(
                                        color: AppColor.primaryRed.of(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    // Text(
                                    //   item.paymentDate != null
                                    //       ? DateFormat(
                                    //           'yyyy-MM-dd',
                                    //         ).format(item.paymentDate!)
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
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            // 플로팅 버튼
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                backgroundColor: AppColor.mainYellow.of(context),
                foregroundColor: AppColor.deepBlack.of(context),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionAddPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  '구독 추가',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: AppColor.containerWhite.of(context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColor.mainBrown.of(context),
        unselectedItemColor: AppColor.gray20.of(context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions_rounded),
            label: '구독 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: '분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }

  // 결제주기 텍스트 변환 함수 예시
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
}
