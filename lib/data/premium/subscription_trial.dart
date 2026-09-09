/// Store-side free trial helpers shared by Play Billing and App Store.
class SubscriptionTrial {
  SubscriptionTrial._();

  static const duration = Duration(days: 7);

  /// Play Billing ISO-8601 periods used for a 7-day introductory phase.
  static bool isSevenDayPeriod(String billingPeriod) {
    final period = billingPeriod.trim().toUpperCase();
    return period == 'P7D' || period == 'P1W';
  }

  static DateTime endsAtFrom(DateTime start) => start.add(duration);

  static DateTime? tryParseStoreDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    return DateTime.tryParse(value) ??
        DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }
}
