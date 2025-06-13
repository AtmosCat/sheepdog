import 'package:flutter/material.dart';
import 'package:sheepdog/theme/colors.dart';

class PaymentMethodCard extends StatelessWidget {
  final String? logoUrl;
  final String? serviceName;
  final String? alias;
  final VoidCallback? onTap;

  const PaymentMethodCard({
    Key? key,
    required this.logoUrl,
    required this.serviceName,
    required this.alias,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasPaymentMethod = (logoUrl != null && logoUrl!.isNotEmpty) || (serviceName != null && serviceName!.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColor.containerWhite.of(context),
              radius: 18,
              child: Icon(
                      Icons.credit_card,
                      color: AppColor.mainYellow.of(context),
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPaymentMethod && serviceName != null && serviceName!.isNotEmpty) ...[
                  Text(
                    serviceName!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  alias ?? "등록된 결제 수단 없음",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: hasPaymentMethod ? Colors.black : AppColor.gray30.of(context),
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
