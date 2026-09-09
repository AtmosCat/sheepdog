import 'package:sheepdog/core/premium/premium_config.dart';

enum PremiumSource { none, iap, restore, firestore }

class PremiumEntitlement {
  const PremiumEntitlement({
    this.isPro = false,
    this.plan,
    this.productId,
    this.source = PremiumSource.none,
    this.hasUsedFreeTrial = false,
    this.trialEndsAt,
    this.updatedAt,
  });

  final bool isPro;
  final PremiumPlan? plan;
  final String? productId;
  final PremiumSource source;
  final bool hasUsedFreeTrial;
  final DateTime? trialEndsAt;
  final DateTime? updatedAt;

  static const free = PremiumEntitlement();

  bool get isInFreeTrial {
    final ends = trialEndsAt;
    if (!isPro || ends == null) return false;
    return ends.isAfter(DateTime.now());
  }

  PremiumEntitlement copyWith({
    bool? isPro,
    PremiumPlan? plan,
    String? productId,
    PremiumSource? source,
    bool? hasUsedFreeTrial,
    DateTime? trialEndsAt,
    DateTime? updatedAt,
    bool clearPlan = false,
    bool clearTrialEndsAt = false,
  }) {
    return PremiumEntitlement(
      isPro: isPro ?? this.isPro,
      plan: clearPlan ? null : (plan ?? this.plan),
      productId: productId ?? this.productId,
      source: source ?? this.source,
      hasUsedFreeTrial: hasUsedFreeTrial ?? this.hasUsedFreeTrial,
      trialEndsAt: clearTrialEndsAt ? null : (trialEndsAt ?? this.trialEndsAt),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'isPro': isPro,
        'plan': plan?.name,
        'productId': productId,
        'source': source.name,
        'hasUsedFreeTrial': hasUsedFreeTrial,
        'trialEndsAt': trialEndsAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory PremiumEntitlement.fromJson(Map<String, dynamic> json) {
    final planName = json['plan'] as String?;
    PremiumPlan? plan;
    if (planName != null) {
      for (final value in PremiumPlan.values) {
        if (value.name == planName) {
          plan = value;
          break;
        }
      }
    }
    final sourceName = json['source'] as String? ?? 'none';
    final source = PremiumSource.values.firstWhere(
      (e) => e.name == sourceName,
      orElse: () => PremiumSource.none,
    );
    final updatedRaw = json['updatedAt'] as String?;
    final trialRaw = json['trialEndsAt'] as String?;
    return PremiumEntitlement(
      isPro: json['isPro'] as bool? ?? false,
      plan: plan,
      productId: json['productId'] as String?,
      source: source,
      hasUsedFreeTrial: json['hasUsedFreeTrial'] as bool? ?? false,
      trialEndsAt: trialRaw == null ? null : DateTime.tryParse(trialRaw),
      updatedAt: updatedRaw == null ? null : DateTime.tryParse(updatedRaw),
    );
  }
}
