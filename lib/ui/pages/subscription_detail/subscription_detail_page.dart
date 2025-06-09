import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/subscription_add/subscription_add_page.dart';
import 'package:sheepdog/ui/pages/widgets/payment_method_card.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

class SubscriptionDetailPage extends StatefulWidget {
  final SubscriptionService service;
  final SubscriptionCategory? category;
  final PaymentMethod? paymentMethod;

  const SubscriptionDetailPage({
    Key? key,
    required this.service,
    this.category,
    this.paymentMethod,
  }) : super(key: key);

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  late SubscriptionService service;
  late SubscriptionCategory? category; // nullable
  late PaymentMethod? paymentMethod;

  @override
  void initState() {
    super.initState();
    service = widget.service;
    category = widget.category; // nullable
    paymentMethod = widget.paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    final deepBlack = AppColor.deepBlack.of(context);

    return Scaffold(
      backgroundColor: AppColor.containerWhite.of(context),
      appBar: AppBar(
        backgroundColor: AppColor.containerWhite.of(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: deepBlack,
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          '구독 상세',
          style: TextStyle(color: deepBlack, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: deepBlack),
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubscriptionAddPage(
                      service: service,
                      category: category,
                      paymentMethod: paymentMethod,
                    ),
                  ),
                );
                if (result == true) {
                  // 수정 완료 후 최신 데이터 다시 불러오기
                  final updatedService = await SubscriptionServiceRepository()
                      .getServiceById(service.id);
                  final updatedCategory = await SubscriptionCategoryRepository()
                      .getCategoryById(updatedService!.categoryId);
                  final updatedPaymentMethod = await PaymentMethodRepository()
                      .getMethodById(updatedService.paymentMethodId);

                  if (mounted) {
                    setState(() {
                      service = updatedService!;
                      category = updatedCategory!;
                      paymentMethod = updatedPaymentMethod!;
                    });
                  }
                }
              } else if (value == 'delete') {
                // 삭제: 한 번 더 묻기
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('구독 삭제'),
                    content: const Text('정말로 이 구독을 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  // 실제 삭제 로직
                  await SubscriptionServiceRepository().deleteService(
                    service.id,
                  );
                  if (context.mounted)
                    Navigator.pop(context, true); // 뒤 페이지로 이동
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('수정')),
              const PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 서비스 이모지 (옅은 회색 원형, 내부 패딩)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      service.emoji ?? '💬',
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리: 없으면 빈 공간(높이만 유지, 칩은 미표시)
                    if (category != null && category!.name.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Color(category!.colorValue!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category!.name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 21), // 칩 높이만큼 빈 공간
                    const SizedBox(height: 4),
                    // 서비스명
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 등록일
                    Text(
                      service.createdAt != null
                          ? '등록일시: ${DateFormat('yyyy.MM.dd HH:mm:ss').format(service.createdAt!)}'
                          : '',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColor.lightGray30.of(context),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // 결제 시작일 섹션
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: AppColor.deepBlack.of(context),
                    size: 22,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '시작일',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.deepBlack.of(context),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors
                      .grey[100], // 또는 AppColor.containerLightGray30.of(context)
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      service.paymentStartDate != null
                          ? DateFormat(
                              'yyyy년 M월 d일',
                            ).format(service.paymentStartDate)
                          : '-',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          // 결제일 섹션
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColor.deepBlack.of(context),
                    size: 22,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '결제일',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.deepBlack.of(context),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors
                      .grey[100], // 또는 AppColor.containerLightGray30.of(context)
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      getPaymentDateDisplay(service),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'D-${getDDay(service.paymentDate!, service.paymentCycle!, service.paymentStartDate)}',
                      style: TextStyle(
                        color: AppColor.primaryRed.of(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),

          // 결제 금액 섹션
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: AppColor.deepBlack.of(context),
                    size: 22,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '결제 금액',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.deepBlack.of(context),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      '${NumberFormat('#,###원', 'ko_KR').format(service.paymentAmount ?? 0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: AppColor.deepBlack.of(context),
                    size: 22,
                  ),
                  const SizedBox(width: 7),
                  Row(
                    children: [
                      Text(
                        '결제 수단',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColor.deepBlack.of(context),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PaymentMethodCard(
                logoUrl: paymentMethod?.logoUrl,
                serviceName: paymentMethod?.serviceName,
                alias: paymentMethod?.alias,
              ),
              const SizedBox(height: 12),
            ],
          ),

          // 메모 섹션
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: AppColor.deepBlack.of(context),
                    size: 22,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '메모',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.deepBlack.of(context),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      service.memo?.isNotEmpty == true
                          ? service.memo!
                          : '메모 없음',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

// 섹션 위젯 예시 (AddSubscriptionPage와 동일하게)
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _SectionCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100], // 또는 AppColor.containerLightGray30.of(context)
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColor.deepBlack.of(context), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColor.deepBlack.of(context),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
