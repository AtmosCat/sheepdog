import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

class CalendarSubscriptionCard extends StatelessWidget {
  final String? emoji;
  final String name;
  final String categoryName;
  final int categoryColor;
  final int? paymentAmount;
  final bool isAmountUndetermined;
  final String paymentCycleText;
  final String paymentDateText;
  final DateTime paymentDate; // 결제 발생 날짜
  final VoidCallback? onTap;

  const CalendarSubscriptionCard({
    Key? key,
    required this.emoji,
    required this.name,
    required this.categoryName,
    required this.categoryColor,
    required this.paymentAmount,
    this.isAmountUndetermined = false,
    required this.paymentCycleText,
    required this.paymentDateText,
    required this.paymentDate,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 이모지
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1,
                          ),
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
                    formatPaymentAmountWithCycle(
                      paymentAmount,
                      isAmountUndetermined: isAmountUndetermined,
                      paymentCycleText: paymentCycleText,
                      paymentDateText: paymentDateText,
                    ),
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
            // 결제 날짜
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dateFormat.format(paymentDate),
                  style: TextStyle(
                    color: AppColor.primaryRed.of(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
