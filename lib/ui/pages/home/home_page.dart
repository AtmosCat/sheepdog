import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/monthly_subscription/monthly_subscription_detail_page.dart';
import 'package:sheepdog/ui/pages/mypage/my_page.dart';
import 'package:sheepdog/ui/pages/subscription_add/subscription_add_page.dart';
import 'package:sheepdog/ui/pages/subscription_detail/subscription_detail_page.dart';
import 'package:sheepdog/ui/pages/subscription_management/subscription_management_page.dart';
import 'package:sheepdog/ui/pages/test_data/test_data_input_page.dart';
import 'package:sheepdog/ui/pages/widgets/subscription_card.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

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
    }).toList()..sort((a, b) => a.paymentDate!.compareTo(b.paymentDate!));

    setState(() {
      _subscriptionList = data;
      _upcomingList = upcoming;
    });
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

    final thisMonthPaidCount = thisMonthList
        .where((item) => getDDay(item.paymentDate, item.paymentCycle) < 0)
        .length;
    final thisMonthPaidAmount = thisMonthList
        .where((item) => getDDay(item.paymentDate, item.paymentCycle) < 0)
        .fold(0, (sum, item) => sum + (item.paymentAmount ?? 0));
    final thisMonthUpcomingCount = thisMonthList
        .where((item) => getDDay(item.paymentDate, item.paymentCycle) >= 0)
        .length;
    final thisMonthUpcomingAmount = thisMonthList
        .where((item) => getDDay(item.paymentDate, item.paymentCycle) >= 0)
        .fold(0, (sum, item) => sum + (item.paymentAmount ?? 0));

    return Scaffold(
      backgroundColor: AppColor.containerWhite.of(context),
      appBar: AppBar(title: const Text('홈'), centerTitle: true),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16), // 원하는 둥근 정도
                          child: Image.asset(
                            'lib/assets/icons/icon6.png',
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
                        Icons.calendar_today,
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MonthlySubscriptionDetailPage(),
                      ),
                    );
                  },

                  child: Padding(
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
                                    backgroundColor: AppColor.mainYellowLight2
                                        .of(context),
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
                                        color: AppColor.primaryGreen.of(
                                          context,
                                        ),
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
                        '결제 임박',
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
                                    item.paymentDate,
                                    item.paymentCycle,
                                  ),
                                  onTap: () async {
                                    final categoryObj =
                                        await SubscriptionCategoryRepository()
                                            .getCategoryById(item.categoryId);
                                    final paymentMethod =
                                        await PaymentMethodRepository()
                                            .getMethodById(
                                              item.paymentMethodId,
                                            );

                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubscriptionDetailPage(
                                          service: item,
                                          category: categoryObj, // null 가능
                                          paymentMethod:
                                              paymentMethod, // null 가능
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
            // 플로팅 버튼
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                backgroundColor: AppColor.mainYellow.of(context),
                foregroundColor: AppColor.deepBlack.of(context),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionAddPage(),
                    ),
                  );
                  if (result == true) {
                    // 구독 추가 성공 시 데이터 새로고침
                    await _loadSubscriptions();
                  }
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
          if (_selectedIndex == index) return; // 이미 선택된 탭이면 아무 동작 안 함
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionManagementPage(),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MyPage()),
              );
              break;
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
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.analytics_rounded),
          //   label: '분석',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}
