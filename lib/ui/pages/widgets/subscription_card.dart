import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/theme/colors.dart';

class SubscriptionCard extends StatelessWidget {
  final String? emoji;
  final String name;
  final String categoryName;
  final int categoryColor;
  final int? paymentAmount;
  final String paymentCycleText;
  final String paymentDateText;
  final int? dDay;
  final VoidCallback? onTap;

  const SubscriptionCard({
    Key? key,
    required this.emoji,
    required this.name,
    required this.categoryName,
    required this.categoryColor,
    required this.paymentAmount,
    required this.paymentCycleText,
    required this.paymentDateText,
    required this.dDay,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###원', 'ko_KR');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                    emoji ?? '💬',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 서비스명, 카테고리, 금액/주기/결제일
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (categoryName.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: Color(categoryColor),
                            borderRadius: BorderRadius.circular(4),
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
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${currencyFormat.format(paymentAmount ?? 0)} ・ $paymentCycleText $paymentDateText',
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
