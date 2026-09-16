import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum PremiumPlan { monthly, yearly }

/// Play / App Store 상품 ID와 카탈로그 가격.
///
/// Play Console:
/// - 구독 상품 1개: [playProductId] (`sheepdog_pro`)
/// - 기본 요금제: [monthlyBasePlanId] (`monthly`), [yearlyBasePlanId] (`yearly`)
/// - 7일 무료 체험 혜택 ID: [playTrialOfferId] (`free-trial-7d`)
///
/// App Store Connect (구독 그룹: 쉽독 Pro):
/// - 월간: [iosMonthlyProductId] (`sheepdog_pro_monthly`)
/// - 연간: [iosYearlyProductId] (`sheepdog_pro_yearly`)
/// - 7일 무료 체험은 각 상품의 Introductory Offer
class PremiumConfig {
  PremiumConfig._();

  static const freeSubscriptionLimit = 5;
  static const freeTrialDays = 7;

  /// Play Console 구독 상품 ID. 월간/연간 모두 이 상품을 조회합니다.
  static const playProductId = 'sheepdog_pro';

  /// App Store 구독 그룹 이름.
  static const iosSubscriptionGroup = '쉽독 Pro';

  /// App Store 월간 상품 ID.
  static const iosMonthlyProductId = 'sheepdog_pro_monthly';

  /// App Store 연간 상품 ID.
  static const iosYearlyProductId = 'sheepdog_pro_yearly';

  static const legacyAndroidProductId = 'premium_android';
  static const legacyIosProductId = 'premium_ios';

  static const monthlyBasePlanId = 'monthly';
  static const yearlyBasePlanId = 'yearly';

  static const playTrialOfferId = 'free-trial-7d';
  static const playTrialOfferTag = playTrialOfferId;

  static Set<String> get queryProductIds {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return {playProductId};
    }
    return {
      iosMonthlyProductId,
      iosYearlyProductId,
      legacyIosProductId,
    };
  }

  static const productIds = {
    playProductId,
    iosMonthlyProductId,
    iosYearlyProductId,
    legacyAndroidProductId,
    legacyIosProductId,
  };

  static const monthlyPriceKrw = 900;
  static const yearlyPriceKrw = 7900;
  static const yearlyListPriceKrw = monthlyPriceKrw * 12;

  static const iconPremium = 'lib/assets/icons/crown.png';

  static int get yearlyDiscountPercent {
    if (yearlyListPriceKrw <= 0) return 0;
    return (((yearlyListPriceKrw - yearlyPriceKrw) * 100) / yearlyListPriceKrw)
        .round();
  }

  static String catalogKey(PremiumPlan plan) => plan.name;

  static bool isKnownProduct(String productId) =>
      productIds.contains(productId);

  static String productIdFor(PremiumPlan plan) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return switch (plan) {
        PremiumPlan.monthly => iosMonthlyProductId,
        PremiumPlan.yearly => iosYearlyProductId,
      };
    }
    return playProductId;
  }

  static String basePlanIdFor(PremiumPlan plan) => switch (plan) {
        PremiumPlan.monthly => monthlyBasePlanId,
        PremiumPlan.yearly => yearlyBasePlanId,
      };

  static PremiumPlan? planForBasePlan(String? basePlanId) {
    if (basePlanId == monthlyBasePlanId) return PremiumPlan.monthly;
    if (basePlanId == yearlyBasePlanId) return PremiumPlan.yearly;
    return null;
  }

  static PremiumPlan? planForProduct(String productId) {
    if (productId == iosYearlyProductId) return PremiumPlan.yearly;
    if (productId == iosMonthlyProductId) {
      return PremiumPlan.monthly;
    }
    if (productId == legacyAndroidProductId ||
        productId == legacyIosProductId) {
      return PremiumPlan.yearly;
    }
    if (productId == playProductId) return PremiumPlan.monthly;
    return null;
  }

  static bool isIosMonthlyProduct(String productId) =>
      productId == iosMonthlyProductId;

  static bool isIosYearlyProduct(String productId) =>
      productId == iosYearlyProductId;

  static bool isPlayTrialOffer({
    required String? offerId,
    required Iterable<String> offerTags,
  }) {
    if (offerId == playTrialOfferId) return true;
    return offerTags.contains(playTrialOfferTag);
  }

  static String formatKrw(int amount) {
    final digits = NumberFormat('#,###', 'ko').format(amount);
    return '$digits원';
  }

  static String catalogPrice(PremiumPlan plan) => switch (plan) {
        PremiumPlan.monthly => formatKrw(monthlyPriceKrw),
        PremiumPlan.yearly => formatKrw(yearlyPriceKrw),
      };

  static String? formatKrwMicros(int priceAmountMicros, String? currencyCode) {
    final code = currencyCode?.toUpperCase();
    if (code != null && code != 'KRW') return null;
    if (priceAmountMicros <= 0) return null;
    final won = (priceAmountMicros / 1000000).round();
    return formatKrw(won);
  }
}

extension PremiumPlanX on PremiumPlan {
  String get label => switch (this) {
        PremiumPlan.monthly => '월간',
        PremiumPlan.yearly => '연간',
      };
}
