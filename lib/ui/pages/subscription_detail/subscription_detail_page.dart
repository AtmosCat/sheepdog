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

class SubscriptionDetailPage extends StatefulWidget {
  final SubscriptionService service;
  final SubscriptionCategory category;
  final PaymentMethod paymentMethod;

  const SubscriptionDetailPage({
    Key? key,
    required this.service,
    required this.category,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  late SubscriptionService service;
  late SubscriptionCategory category;
  late PaymentMethod paymentMethod;

  @override
  void initState() {
    super.initState();
    service = widget.service;
    category = widget.category;
    paymentMethod = widget.paymentMethod;
  }

  // 결제일 텍스트 변환
  String _paymentDateText() {
    if (service.paymentCycle == PaymentCycle.yearly &&
        service.paymentDate != null) {
      return '매년 ${service.paymentDate!.month}월 ${service.paymentDate!.day}일';
    }
    if (service.paymentCycle == PaymentCycle.monthly &&
        service.paymentDate != null) {
      return '매월 ${service.paymentDate!.day}일';
    }
    if (service.paymentCycle == PaymentCycle.weekly &&
        service.paymentDate != null) {
      const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
      return '매주 ${weekDays[service.paymentDate!.weekday - 1]}요일';
    }
    return '';
  }

  int _getDDay() {
    if (service.paymentDate == null || service.paymentCycle == null)
      return 9999;
    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final payDate = DateTime(
      service.paymentDate!.year,
      service.paymentDate!.month,
      service.paymentDate!.day,
    );
    final diff = payDate.difference(nowDate).inDays;
    if (diff >= 0) return diff;
    // 결제일이 지났으면 다음 결제일까지 남은 일수 계산
    if (service.paymentCycle == PaymentCycle.monthly) {
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
        final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        nextPayDate = DateTime(nextYear, nextMonth, lastDay);
      }
      return nextPayDate.difference(nowDate).inDays;
    } else if (service.paymentCycle == PaymentCycle.yearly) {
      int nextYear = payDate.year + 1;
      DateTime nextPayDate;
      try {
        nextPayDate = DateTime(nextYear, payDate.month, payDate.day);
      } catch (_) {
        final lastDay = DateTime(nextYear, payDate.month + 1, 0).day;
        nextPayDate = DateTime(nextYear, payDate.month, lastDay);
      }
      return nextPayDate.difference(nowDate).inDays;
    } else if (service.paymentCycle == PaymentCycle.weekly) {
      int currentWeekday = nowDate.weekday;
      int payWeekday = payDate.weekday;
      int daysUntilNext = (payWeekday - currentWeekday) % 7;
      if (daysUntilNext <= 0) daysUntilNext += 7;
      return daysUntilNext;
    }
    return 9999;
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
                    // 카테고리
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(category.colorValue!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
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
                    // 등록일 (불가능하면 주석 처리)
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
                      _paymentDateText(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'D-${_getDDay()}',
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

          // 결제 수단 섹션
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
                    CircleAvatar(
                      backgroundColor: AppColor.containerWhite.of(context),
                      radius: 18,
                      child: paymentMethod.logoUrl != null
                          ? Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: ClipOval(
                                child: Image.asset(
                                  paymentMethod.logoUrl!,
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.credit_card,
                              color: AppColor.mainBrown.of(context),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paymentMethod.serviceName ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        Text(
                          paymentMethod.alias,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
