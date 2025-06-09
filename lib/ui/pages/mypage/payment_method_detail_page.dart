import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/subscription_detail/subscription_detail_page.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

// PaymentMethod, SubscriptionService, SubscriptionCategoryRepository, SubscriptionServiceRepository 등 필요

class PaymentMethodDetailPage extends StatefulWidget {
  final PaymentMethod paymentMethod;

  const PaymentMethodDetailPage({Key? key, required this.paymentMethod})
    : super(key: key);

  @override
  State<PaymentMethodDetailPage> createState() =>
      _PaymentMethodDetailPageState();
}

class _PaymentMethodDetailPageState extends State<PaymentMethodDetailPage> {
  List<SubscriptionService> _subscriptions = [];
  bool _loading = true;
  late PaymentMethod paymentMethod;

  @override
  void initState() {
    super.initState();
    paymentMethod = widget.paymentMethod;
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final repo = SubscriptionServiceRepository();
    final list = await repo.getAllServices();
    setState(() {
      _subscriptions = list
          .where((s) => s.paymentMethodId == widget.paymentMethod.id)
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.containerWhite.of(context),
      appBar: AppBar(
        backgroundColor: AppColor.containerWhite.of(context),
        elevation: 0,
        centerTitle: true,
        title: Text(
          '결제수단 상세',
          style: TextStyle(
            color: AppColor.deepBlack.of(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColor.deepBlack.of(context)),
            onSelected: (value) async {
              if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      '결제수단 삭제',
                      style: TextStyle(fontSize: 18),
                    ),
                    content: const Text('이 결제수단을 삭제하시겠습니까?'),
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
                  // 1. DB에서 해당 결제수단 삭제
                  await PaymentMethodRepository().deleteMethod(
                    paymentMethod.id,
                  );

                  // 2. 해당 결제수단으로 등록된 구독 서비스들의 결제수단을 null로 업데이트
                  final subscriptionRepo = SubscriptionServiceRepository();
                  final allSubscriptions = await subscriptionRepo
                      .getAllServices();
                  final affected = allSubscriptions
                      .where((s) => s.paymentMethodId == paymentMethod.id)
                      .toList();

                  for (final sub in affected) {
                    final updated = sub.copyWith(paymentMethodId: null);
                    await subscriptionRepo.updateService(updated);
                  }

                  if (context.mounted) Navigator.pop(context, true);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 로고, 이름, 별칭, 등록일시
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: AppColor.containerWhite.of(context),
                  radius: 32,
                  child: paymentMethod.logoUrl != null
                      ? Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: ClipOval(
                            child: Image.asset(
                              paymentMethod.logoUrl!,
                              width: 38,
                              height: 38,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.credit_card,
                          color: AppColor.mainBrown.of(context),
                          size: 32,
                        ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 금융기관 이름(작게)
                      Text(
                        paymentMethod.serviceName ?? '',
                        style: TextStyle(
                          color: AppColor.deepBlack.of(context),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 별칭(크게) + 수정 버튼
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            paymentMethod.alias,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: AppColor.deepBlack.of(context),
                            ),
                            onPressed: () async {
                              final controller = TextEditingController(
                                text: paymentMethod.alias,
                              );
                              final newAlias = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                      '이름 수정',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        hintText: '새 이름 입력',
                                      ),
                                      autofocus: true,
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final trimmed = controller.text
                                              .trim();
                                          if (trimmed.isNotEmpty) {
                                            Navigator.pop(context, trimmed);
                                          }
                                        },
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (newAlias != null &&
                                  newAlias.isNotEmpty &&
                                  newAlias != paymentMethod.alias) {
                                final updated = paymentMethod.copyWith(
                                  alias: newAlias,
                                );
                                await PaymentMethodRepository().updateMethod(
                                  updated,
                                );
                                if (mounted) {
                                  setState(() {
                                    paymentMethod = updated;
                                  });
                                  SnackbarUtil.showToastMessage(
                                    '이름이 수정되었습니다.',
                                  ); // Toast 메시지
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 등록일시(아래, 작게)
                      Text(
                        paymentMethod.createdAt != null
                            ? '등록일시: ${DateFormat('yyyy.MM.dd HH:mm:ss').format(paymentMethod.createdAt!)}'
                            : '',
                        style: TextStyle(
                          fontSize: 12,
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
            // "등록된 정기 결제" + 총 ?건
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '등록된 정기 결제',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColor.deepBlack.of(context),
                    fontSize: 15,
                  ),
                ),
                Text(
                  '총 ${_subscriptions.length}건',
                  style: TextStyle(
                    color: AppColor.gray30.of(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 구독 서비스 리스트(섹션 양식)
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _subscriptions.isEmpty
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
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _subscriptions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, idx) {
                        final item = _subscriptions[idx];
                        return GestureDetector(
                          onTap: () async {
                            final category =
                                await SubscriptionCategoryRepository()
                                    .getCategoryById(item.categoryId);
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
                                await _loadSubscriptions();
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
                                                      BorderRadius.circular(4),
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
                                        '${NumberFormat('#,###원', 'ko_KR').format(item.paymentAmount ?? 0)} ・ ${cycleToText(item.paymentCycle)} ${paymentDateText(item)}',
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
                                      'D-${getDDay(item.paymentDate!, item.paymentCycle!, item.paymentStartDate)}',
                                      style: TextStyle(
                                        color: AppColor.primaryRed.of(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
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
    );
  }
}
