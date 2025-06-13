import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:sheepdog/ui/utils/fcm_utils.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

class SubscriptionDetailPage extends StatefulWidget {
  final String subscriptionId;

  const SubscriptionDetailPage({Key? key, required this.subscriptionId})
    : super(key: key);

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  SubscriptionService? service;
  SubscriptionCategory? category;
  PaymentMethod? paymentMethod;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
    });
    final s = await SubscriptionServiceRepository().getServiceById(
      widget.subscriptionId,
    );
    final c = s != null
        ? await SubscriptionCategoryRepository().getCategoryById(s.categoryId)
        : null;
    final p = s != null
        ? await PaymentMethodRepository().getMethodById(s.paymentMethodId)
        : null;
    setState(() {
      service = s;
      category = c;
      paymentMethod = p;
      _loading = false;
    });
  }

  // 수정/삭제 후 최신화
  Future<void> _refreshAfterEdit() async {
    await _fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final deepBlack = AppColor.deepBlack.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.containerWhite.of(context),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (service == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.containerWhite.of(context),
          elevation: 0,
        ),
        body: const Center(child: Text('구독 정보를 찾을 수 없습니다.')),
      );
    }

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
                      service: service!,
                      category: category,
                      paymentMethod: paymentMethod,
                    ),
                  ),
                );
                if (result == true) {
                  await _refreshAfterEdit();
                }
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('구독 삭제'),
                    content: const Text('정말로 이 구독을 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: AppColor.mainYellow.of(context),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                          SnackbarUtil.showToastMessage("구독이 삭제되었습니다.");
                        },
                        child: Text(
                          '삭제',
                          style: TextStyle(
                            color: AppColor.defaultBlack.of(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await SubscriptionServiceRepository().deleteService(
                    service!.id,
                  );
                  final updatedSubscriptions =
                      await SubscriptionServiceRepository().getAllServices();
                  final String? fcmToken = await FirebaseMessaging.instance
                      .getToken();
                  if (fcmToken == null) {
                    SnackbarUtil.showToastMessage('알림 설정을 위해 FCM 토큰이 필요합니다.');
                    return;
                  }
                  await FCMUtils().saveUserNotificationSettings(
                    subscriptions: updatedSubscriptions,
                  );
                  if (context.mounted) Navigator.pop(context, true);
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
                      service!.emoji ?? '💬',
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
                      service!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 등록일
                    Text(
                      service!.createdAt != null
                          ? '등록일시: ${DateFormat('yyyy.MM.dd HH:mm:ss').format(service!.createdAt!)}'
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
                      DateFormat(
                        'yyyy년 M월 d일',
                      ).format(service!.paymentStartDate),
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
                      getPaymentDateDisplay(service!),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Builder(
                      builder: (context) {
                        final dDay = getDDay(
                          service!.paymentDate!,
                          service!.paymentCycle!,
                          service!.paymentStartDate,
                        );
                        return Text(
                          dDay == 0 ? 'D-day' : 'D-$dDay',
                          style: TextStyle(
                            color: AppColor.primaryRed.of(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        );
                      },
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
                      '${NumberFormat('#,###원', 'ko_KR').format(service!.paymentAmount ?? 0)}',
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
                      service!.memo.isNotEmpty == true
                          ? service!.memo
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
