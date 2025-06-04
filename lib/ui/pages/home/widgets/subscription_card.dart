import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/theme/colors.dart';

// 카드 위젯 분리
class SubscriptionCard extends StatelessWidget {
  final String? logoUrl;
  final String brand;
  final String category;
  final AppColor categoryColor;
  final int amount;
  final String cycle;
  final int date;
  final int dDay;

  const SubscriptionCard({
    Key? key,
    this.logoUrl,
    required this.brand,
    required this.category,
    required this.categoryColor,
    required this.amount,
    required this.cycle,
    required this.date,
    required this.dDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUrgent = dDay <= 3;
    final currencyFormat = NumberFormat('#,###원', 'ko_KR');

    return Container(
      decoration: BoxDecoration(
        color: AppColor.containerLightGray30.of(context), // 옅은 회색 배경
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadowBlack.of(context).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColor.mainYellowLight3.of(context),
                shape: BoxShape.circle,
              ),
              child: logoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        logoUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.apps,
                      color: AppColor.mainBrown.of(context),
                      size: 28,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          brand,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColor.deepBlack.of(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.of(context),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${currencyFormat.format(amount)} ・ $cycle $date일',
                    style: TextStyle(
                      color: AppColor.gray30.of(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: isUrgent
                    ? AppColor.primaryRed.of(context)
                    : AppColor.mainYellow.of(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'D-$dDay',
                style: TextStyle(
                  color: isUrgent
                      ? Colors.white
                      : AppColor.deepBlack.of(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
