import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'package:sheepdog/ui/pages/home/widgets/main_bottom_navigation_bar.dart';
import 'package:sheepdog/ui/pages/mypage/my_page.dart';
import 'package:sheepdog/ui/pages/subscription_add/subscription_add_page.dart';
import 'package:sheepdog/ui/pages/subscription_detail/subscription_detail_page.dart';
import 'package:sheepdog/ui/pages/widgets/subscription_card.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

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
      } else if (categoryId == 'none') {
        filtered = _allSubscriptions
            .where((s) => s.categoryId == null)
            .toList();
      } else {
        filtered = _allSubscriptions
            .where((s) => s.categoryId == categoryId)
            .toList();
      }
      // dDay 임박한 순으로 정렬
      filtered.sort(
        (a, b) => getDDay(a.paymentDate!, a.paymentCycle!, a.paymentStartDate)
            .compareTo(
              getDDay(b.paymentDate!, b.paymentCycle!, b.paymentStartDate),
            ),
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
                  // 일반 카테고리
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
                  // "카테고리 없음" 버튼
                  GestureDetector(
                    onTap: () => _onCategorySelected('none'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedCategoryId == 'none'
                            ? AppColor.gray10.of(context)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedCategoryId == 'none')
                            Icon(Icons.check, size: 16, color: Colors.black),
                          if (_selectedCategoryId == 'none')
                            const SizedBox(width: 4),
                          Text(
                            '카테고리 없음',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: _selectedCategoryId == 'none'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
                              dDay: getDDay(
                                item.paymentDate!,
                                item.paymentCycle!,
                                item.paymentStartDate,
                              ),
                              onTap: () async {
                                final category =
                                    await SubscriptionCategoryRepository()
                                        .getCategoryById(item.categoryId);
                                final paymentMethod =
                                    await PaymentMethodRepository()
                                        .getMethodById(item.paymentMethodId);

                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SubscriptionDetailPage(
                                      service: item,
                                      category: category, // nullable
                                      paymentMethod: paymentMethod,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  await _loadData();
                                }
                              },
                            );
                          },
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
      bottomNavigationBar: MainBottomNavigationBar(
        selectedIndex: 1,
      ),
    );
  }
}
