import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'package:sheepdog/ui/pages/subscription_add/subscription_add_page.dart';
import 'package:sheepdog/ui/pages/subscription_detail/subscription_detail_page.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends State<SubscriptionManagementPage> {
  List<SubscriptionService> _allSubscriptions = [];
  List<SubscriptionService> _filteredSubscriptions = [];
  List<SubscriptionCategory> _categories = [];
  String _selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // DB에서 구독 서비스 및 카테고리 불러오기
    final repo = SubscriptionServiceRepository();
    final categoryRepo = SubscriptionCategoryRepository();
    final subs = await repo.getAllServices();
    final cats = await categoryRepo.getAllCategories();

    setState(() {
      _allSubscriptions = subs;
      _categories = cats;
      _selectedCategoryId = 'all';
      _filteredSubscriptions = subs;
    });
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      List<SubscriptionService> filtered;
      if (categoryId == 'all') {
        filtered = List.from(_allSubscriptions);
      } else {
        filtered = _allSubscriptions
            .where((s) => s.categoryId == categoryId)
            .toList();
      }
      // dDay 임박한 순으로 정렬
      filtered.sort(
        (a, b) => getDDay(
          a.paymentDate,
          a.paymentCycle,
        ).compareTo(getDDay(b.paymentDate, b.paymentCycle)),
      );
      _filteredSubscriptions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainYellow = AppColor.mainYellow.of(context);
    final deepBlack = AppColor.deepBlack.of(context);

    return Scaffold(
      backgroundColor: AppColor.containerWhite.of(context),
      appBar: AppBar(
        backgroundColor: AppColor.containerWhite.of(context),
        elevation: 0,
        title: const Text(
          '구독 관리',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 텍스트
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '총 ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: deepBlack,
                        height: 1.3,
                      ),
                    ),
                    TextSpan(
                      text: '${_allSubscriptions.length}건',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColor.mainBrown.of(context),
                        height: 1.3, // 원하는 색상으로 변경
                        // 예: mainYellow, Colors.blue, 등등
                      ),
                    ),
                    TextSpan(
                      text: '의\n정기결제가 발생하고 있어요.',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: deepBlack,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),
            // 카테고리 가로 스크롤
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // "전체" 카테고리
                  GestureDetector(
                    onTap: () => _onCategorySelected('all'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedCategoryId == 'all'
                            ? AppColor.gray10.of(context)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedCategoryId == 'all')
                            Icon(Icons.check, size: 16, color: Colors.black),
                          if (_selectedCategoryId == 'all')
                            const SizedBox(width: 4),
                          Text(
                            '전체',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: _selectedCategoryId == 'all'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._categories.map(
                    (cat) => GestureDetector(
                      onTap: () => _onCategorySelected(cat.id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(cat.colorValue!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedCategoryId == cat.id)
                              Icon(Icons.check, size: 16, color: Colors.black),
                            if (_selectedCategoryId == cat.id)
                              const SizedBox(width: 4),
                            Text(
                              cat.name,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: _selectedCategoryId == cat.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            // 구독 서비스 리스트업
            Expanded(
              child: _filteredSubscriptions.isEmpty
                  ? Center(
                      child: Text(
                        '등록된 정기 결제가 없습니다.',
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
                            // 카테고리 객체 찾기
                            final category =
                                await SubscriptionCategoryRepository()
                                    .getCategoryById(item.categoryId);

                            // 결제수단 객체 찾기
                            final paymentMethod =
                                await PaymentMethodRepository().getMethodById(
                                  item.paymentMethodId,
                                );

                            if (category != null && paymentMethod != null) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubscriptionDetailPage(
                                    service: item,
                                    category: category,
                                    paymentMethod: paymentMethod,
                                  ),
                                ),
                              );
                              if (result == true) {
                                await _loadData(); // 또는 _loadSubscriptions(), _refreshList() 등 데이터 새로고침 함수
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('상세 정보를 불러올 수 없습니다.'),
                                ),
                              );
                            }
                          },
                          child: Container(
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
                                          FutureBuilder<SubscriptionCategory?>(
                                            future:
                                                SubscriptionCategoryRepository()
                                                    .getCategoryById(
                                                      item.categoryId,
                                                    ),
                                            builder: (context, snapshot) {
                                              final cat = snapshot.data;
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Color(
                                                    cat?.colorValue ??
                                                        0xFFF5F5F5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                ),
                                                child: Text(
                                                  cat?.name ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${NumberFormat('#,###원', 'ko_KR').format(item.paymentAmount ?? 0)} ・ ${_cycleToText(item.paymentCycle)} ${_paymentDateText(item)}',
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
                                      'D-${getDDay(item.paymentDate, item.paymentCycle)}',
                                      style: TextStyle(
                                        color: AppColor.primaryRed.of(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
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
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // 플로팅 버튼
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColor.mainYellow.of(context),
        foregroundColor: AppColor.deepBlack.of(context),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionAddPage()),
          );
          if (result == true) {
            await _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(
          '구독 추가',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // 구독 관리 인덱스
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 2) {
            // 분석 페이지로 이동
          } else if (index == 3) {
            // 마이페이지로 이동
          }
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

  // 결제주기 텍스트 변환 함수
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

  // 결제일 텍스트 변환 함수
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
}
