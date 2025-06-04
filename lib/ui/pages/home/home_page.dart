import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/home/widgets/subscription_card.dart';
import 'package:sheepdog/ui/pages/subscription_add/subscription_add_page.dart';
import 'package:sheepdog/ui/pages/test_data/test_data_input_page.dart';

// AppColor, AppColors, AppColorExtension이 이미 정의되어 있다고 가정합니다.

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _selectedIndex = 0;

  // 임시 데이터 (DB 연동 전)
  final int thisMonthTotalAmount = 120000;
  final int thisMonthTotalCount = 6;
  final int thisMonthPaidAmount = 80000;
  final int thisMonthPaidCount = 4;
  final int thisMonthUpcomingAmount = 40000;
  final int thisMonthUpcomingCount = 2;
  final int alarmCount = 2;

  final List<Map<String, dynamic>> subscriptionList = [
    {
      'logo':
          'https://upload.wikimedia.org/wikipedia/commons/7/75/Netflix_icon.svg',
      'brand': '넷플릭스',
      'category': 'OTT',
      'categoryColor': AppColor.mainBrown,
      'amount': 17000,
      'cycle': '매달',
      'date': 12,
      'dDay': 2,
    },
    {
      'logo':
          'https://upload.wikimedia.org/wikipedia/commons/4/44/Spotify_Logo.png',
      'brand': '스포티파이',
      'category': '뮤직',
      'categoryColor': AppColor.primaryGreen,
      'amount': 10900,
      'cycle': '매달',
      'date': 15,
      'dDay': 3,
    },
    {
      'logo': null,
      'brand': 'SKT',
      'category': '통신요금',
      'categoryColor': AppColor.primaryBlue,
      'amount': 45000,
      'cycle': '매달',
      'date': 25,
      'dDay': 1,
    },
  ];

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // 페이지 이동 처리 (추후 push, pushAndRemoveUntil 등 상황에 맞게 교체)
    // 예시: Navigator.pushNamed(context, '/route');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = now.month;
    final currencyFormat = NumberFormat('#,###원', 'ko_KR');

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
                      // 앱 아이콘 자리
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
                        children: [
                          // 원형 ProgressIndicator + 월
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 68,
                                height: 68,
                                child: CircularProgressIndicator(
                                  value:
                                      thisMonthPaidCount /
                                      (thisMonthTotalCount == 0
                                          ? 1
                                          : thisMonthTotalCount),
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
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${currencyFormat.format(thisMonthTotalAmount)} ・ ${thisMonthTotalCount}건',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: AppColor.deepBlack.of(context),
                                  ),
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
                                    Text(
                                      '결제 완료: ${currencyFormat.format(thisMonthPaidAmount)} ・ ${thisMonthPaidCount}건',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColor.gray30.of(context),
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
                                    Text(
                                      '결제 예정: ${currencyFormat.format(thisMonthUpcomingAmount)} ・ ${thisMonthUpcomingCount}건',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColor.gray30.of(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.chevron_right,
                              color: AppColor.gray20.of(context),
                              size: 30,
                            ),
                            onPressed: () {
                              // 상세 페이지 이동 처리
                            },
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
                        '총 $alarmCount건',
                        style: TextStyle(
                          color: AppColor.gray20.of(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: List.generate(subscriptionList.length, (index) {
                      final item = subscriptionList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SubscriptionCard(
                          logoUrl: item['logo'],
                          brand: item['brand'],
                          category: item['category'],
                          categoryColor: item['categoryColor'],
                          amount: item['amount'],
                          cycle: item['cycle'],
                          date: item['date'],
                          dDay: item['dDay'],
                        ),
                      );
                    }),
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
        onTap: _onNavTapped,
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
}
