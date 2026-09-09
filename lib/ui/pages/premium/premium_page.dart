import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/core/premium/premium_config.dart';
import 'package:sheepdog/data/premium/premium_controller.dart';
import 'package:sheepdog/data/premium/premium_models.dart';
import 'package:sheepdog/theme/colors.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  PremiumPlan _plan = PremiumPlan.yearly;

  static const _accent = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumController>();
    final muted = AppColor.gray20.of(context);
    final primaryText = AppColor.deepBlack.of(context);
    final selectedPlan =
        premium.isPro ? (premium.entitlement.plan ?? _plan) : _plan;

    return Scaffold(
      backgroundColor: AppColor.scaffoldGray.of(context),
      appBar: AppBar(
        title: const Text('쉽독 Pro'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Center(
                  child: Image.asset(
                    PremiumConfig.iconPremium,
                    width: 88,
                    height: 88,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '쉽독 Pro 구독',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '광고 없이, 결제일 알림과 구독 달력, 무제한 구독 관리를 이용해 보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.4, color: muted),
                ),
                if (premium.isPro) ...[
                  const SizedBox(height: 12),
                  _SubscribedBanner(entitlement: premium.entitlement),
                ],
                const SizedBox(height: 24),
                Text(
                  '혜택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                const _BenefitTile(
                  icon: Icons.block,
                  text: '앱 내 모든 광고 제거',
                ),
                const _BenefitTile(
                  icon: Icons.notifications_active_outlined,
                  text: '결제일 알림 발송 기능 사용 가능',
                ),
                const _BenefitTile(
                  icon: Icons.calendar_month_outlined,
                  text: '구독 달력 사용 가능',
                ),
                const _BenefitTile(
                  icon: Icons.all_inclusive,
                  text: '개수 제한 없이 구독 서비스 추가',
                ),
                const SizedBox(height: 20),
                Text(
                  '요금제',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                _PlanCard(
                  selected: selectedPlan == PremiumPlan.monthly,
                  title: '월간 플랜',
                  price: premium.storePrices[
                          PremiumConfig.catalogKey(PremiumPlan.monthly)] ??
                      PremiumConfig.catalogPrice(PremiumPlan.monthly),
                  period: '매월',
                  onTap: premium.isPro
                      ? null
                      : () => setState(() => _plan = PremiumPlan.monthly),
                ),
                const SizedBox(height: 10),
                _PlanCard(
                  selected: selectedPlan == PremiumPlan.yearly,
                  title: '연간 플랜',
                  price: premium.storePrices[
                          PremiumConfig.catalogKey(PremiumPlan.yearly)] ??
                      PremiumConfig.catalogPrice(PremiumPlan.yearly),
                  period: '매년',
                  listPrice: PremiumConfig.formatKrw(
                    PremiumConfig.yearlyListPriceKrw,
                  ),
                  discountPercent: PremiumConfig.yearlyDiscountPercent,
                  badge: '추천',
                  onTap: premium.isPro
                      ? null
                      : () => setState(() => _plan = PremiumPlan.yearly),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!premium.isPro) ...[
                    Text(
                      premium.canStartFreeTrial(_plan)
                          ? '7일 무료 체험 후, 취소하지 않으면 ${_plan.label} 요금제로 자동 결제됩니다. 체험은 1회만 가능합니다.'
                          : '선택한 요금제로 구독합니다. 취소하기 전까지 자동 갱신됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.35, color: muted),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _accent.withValues(alpha: 0.4),
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: premium.isPro || premium.busy
                          ? null
                          : () => context.read<PremiumController>().buy(_plan),
                      child: premium.busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              premium.isPro
                                  ? '구독 중'
                                  : premium.canStartFreeTrial(_plan)
                                      ? '무료 체험하기'
                                      : '${_plan.label} 구독하기',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribedBanner extends StatelessWidget {
  const _SubscribedBanner({required this.entitlement});
  final PremiumEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final plan = entitlement.plan?.label ?? 'Pro';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        entitlement.isInFreeTrial
            ? '7일 무료 체험 이용 중입니다. 취소하지 않으면 $plan 요금제로 자동 갱신됩니다.'
            : '현재 $plan 구독 이용 중입니다.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF007AFF),
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF007AFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.4,
                fontSize: 14,
                color: AppColor.defaultBlack.of(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.title,
    required this.price,
    required this.period,
    required this.onTap,
    this.listPrice,
    this.discountPercent,
    this.badge,
  });

  final bool selected;
  final String title;
  final String price;
  final String period;
  final VoidCallback? onTap;
  final String? listPrice;
  final int? discountPercent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF007AFF);
    final border = selected ? accent : AppColor.divider.of(context);
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.12)
          : AppColor.containerWhite.of(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? accent : AppColor.lightGray30.of(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColor.deepBlack.of(context),
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (listPrice != null)
                      Text(
                        listPrice!,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColor.lightGray30.of(context),
                          fontSize: 13,
                        ),
                      ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: price,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColor.deepBlack.of(context),
                            ),
                          ),
                          TextSpan(
                            text: ' / $period',
                            style: TextStyle(
                              color: AppColor.gray20.of(context),
                            ),
                          ),
                          if (discountPercent != null && discountPercent! > 0)
                            TextSpan(
                              text: '  $discountPercent% 할인',
                              style: const TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
