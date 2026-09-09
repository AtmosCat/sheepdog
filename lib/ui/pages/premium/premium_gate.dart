import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/data/premium/premium_controller.dart';
import 'package:sheepdog/ui/pages/premium/premium_page.dart';

void openSheepdogPro(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => const PremiumPage()),
  );
}

bool isSheepdogPro(BuildContext context) {
  return context.read<PremiumController>().isPro;
}

/// Returns true if the caller should abort (paywall opened).
bool gateSheepdogPro(BuildContext context) {
  if (isSheepdogPro(context)) return false;
  openSheepdogPro(context);
  return true;
}
