import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/core/premium/premium_config.dart';
import 'package:sheepdog/data/premium/premium_controller.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/premium/premium_gate.dart';

class FreeAppLimitButton extends StatelessWidget {
  final int currentCount;
  final Future<void> Function() onAdd;
  final Future<void> Function()? onReload;
  final BuildContext parentContext;

  const FreeAppLimitButton({
    super.key,
    required this.currentCount,
    required this.onAdd,
    this.onReload,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: FloatingActionButton.extended(
        backgroundColor: AppColor.mainYellow.of(context),
        foregroundColor: AppColor.deepBlack.of(context),
        icon: const Icon(Icons.add),
        label: const Text(
          '구독 추가',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: () async {
          final isPro = context.read<PremiumController>().isPro;
          if (!isPro && currentCount >= PremiumConfig.freeSubscriptionLimit) {
            openSheepdogPro(parentContext);
            return;
          }
          await onAdd();
          if (onReload != null) await onReload!();
        },
      ),
    );
  }
}
