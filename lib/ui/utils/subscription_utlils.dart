import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_service.dart';

const String kUndeterminedAmountLabel = '금액이 정해지지 않음';

String formatPaymentAmountLabel(
  int? paymentAmount, {
  bool isAmountUndetermined = false,
}) {
  if (isAmountUndetermined) return kUndeterminedAmountLabel;
  if (paymentAmount == null) return '';
  return NumberFormat('#,###원', 'ko_KR').format(paymentAmount);
}

String formatPaymentAmountWithCycle(
  int? paymentAmount, {
  bool isAmountUndetermined = false,
  required String paymentCycleText,
  required String paymentDateText,
}) {
  final amountPart = formatPaymentAmountLabel(
    paymentAmount,
    isAmountUndetermined: isAmountUndetermined,
  );
  return '$amountPart ・ $paymentCycleText $paymentDateText';
}

int sumSubscriptionPaymentAmounts(Iterable<SubscriptionService> services) {
  return services
      .where((s) => !serviceIsAmountUndetermined(s) && s.paymentAmount != null)
      .fold(0, (sum, s) => sum + s.paymentAmount!);
}

/// hot reload·구버전 DB에서도 안전하게 bool 필드를 읽습니다.
bool serviceIsAmountUndetermined(SubscriptionService service) {
  final value = (service as dynamic).isAmountUndetermined;
  return value == true;
}

bool serviceIsLastDayOfMonth(SubscriptionService service) {
  final value = (service as dynamic).isLastDayOfMonth;
  return value == true;
}

/// 결제주기 텍스트 변환
String cycleToText(PaymentCycle? cycle) {
  switch (cycle) {
    case PaymentCycle.yearly:
      return '매년';
    case PaymentCycle.monthly:
      return '매월';
    case PaymentCycle.weekly:
      return '매주';
    default:
      return '';
  }
}

/// 해당 연월의 실제 결제일 (말일 / 29·30·31일 보정 포함)
/// Dart DateTime은 존재하지 않는 날짜를 overflow 시키므로 반드시 이 헬퍼를 사용한다.
DateTime resolveMonthlyPaymentDate(
  int year,
  int month, {
  required int preferredDay,
  bool isLastDayOfMonth = false,
}) {
  final lastDay = DateTime(year, month + 1, 0).day;
  if (isLastDayOfMonth) {
    return DateTime(year, month, lastDay);
  }
  final day = preferredDay > lastDay ? lastDay : preferredDay;
  return DateTime(year, month, day);
}

DateTime resolveServiceMonthlyDate(
  SubscriptionService service,
  int year,
  int month,
) {
  return resolveMonthlyPaymentDate(
    year,
    month,
    preferredDay: service.paymentDate?.day ?? 1,
    isLastDayOfMonth: serviceIsLastDayOfMonth(service),
  );
}

/// 결제일 텍스트 변환 (카드, 리스트 등에서 사용)
String paymentDateText(SubscriptionService item) {
  if (item.paymentCycle == PaymentCycle.yearly && item.paymentDate != null) {
    return '${item.paymentDate!.month}월 ${item.paymentDate!.day}일';
  }
  if (item.paymentCycle == PaymentCycle.monthly && item.paymentDate != null) {
    if (serviceIsLastDayOfMonth(item)) return '말일';
    return '${item.paymentDate!.day}일';
  }
  if (item.paymentCycle == PaymentCycle.weekly && item.paymentDate != null) {
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${weekDays[item.paymentDate!.weekday - 1]}요일';
  }
  return '';
}

/// 결제일 디스플레이용 텍스트 (상세)
String getPaymentDateDisplay(SubscriptionService item) {
  if (item.paymentCycle == PaymentCycle.yearly && item.paymentDate != null) {
    return '매년 ${item.paymentDate!.month}월 ${item.paymentDate!.day}일';
  }
  if (item.paymentCycle == PaymentCycle.monthly && item.paymentDate != null) {
    if (serviceIsLastDayOfMonth(item)) return '매월 말일';
    return '매월 ${item.paymentDate!.day}일';
  }
  if (item.paymentCycle == PaymentCycle.weekly && item.paymentDate != null) {
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    return '매주 ${weekDays[item.paymentDate!.weekday - 1]}요일';
  }
  return '';
}

List<DateTime> getPaymentDatesInMonth(
  SubscriptionService service,
  DateTime month,
) {
  final List<DateTime> dates = [];
  if (service.paymentDate == null || service.paymentCycle == null) return dates;
  if (service.paymentCycle == PaymentCycle.monthly) {
    final date = resolveServiceMonthlyDate(service, month.year, month.month);
    if (!date.isBefore(service.paymentStartDate)) {
      dates.add(date);
    }
  } else if (service.paymentCycle == PaymentCycle.weekly) {
    final weekday = service.paymentDate!.weekday;
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    for (int d = 1; d <= lastDay; d++) {
      final date = DateTime(month.year, month.month, d);
      if (date.weekday == weekday && !date.isBefore(service.paymentStartDate)) {
        dates.add(date);
      }
    }
  } else if (service.paymentCycle == PaymentCycle.yearly) {
    final monthMatch = service.paymentDate!.month;
    final day = service.paymentDate!.day;
    if (month.month == monthMatch) {
      final lastDay = DateTime(month.year, monthMatch + 1, 0).day;
      final date = DateTime(
        month.year,
        monthMatch,
        day > lastDay ? lastDay : day,
      );
      if (!date.isBefore(service.paymentStartDate)) {
        dates.add(date);
      }
    }
  }
  return dates;
}

/// D-day 계산 (시작일 필수)
int getDDay(
  DateTime paymentDate,
  PaymentCycle paymentCycle,
  DateTime startDate, {
  bool isLastDayOfMonth = false,
}) {
  final now = DateTime.now();
  final nowDate = DateTime(now.year, now.month, now.day);
  final start = DateTime(startDate.year, startDate.month, startDate.day);

  // 기준일: 오늘과 시작일 중 더 늦은 날짜
  final baseDate = nowDate.isBefore(start) ? start : nowDate;

  if (paymentCycle == PaymentCycle.weekly) {
    int targetWeekday = paymentDate.weekday;
    int daysUntilFirst = (targetWeekday - baseDate.weekday) % 7;
    if (daysUntilFirst < 0) daysUntilFirst += 7;
    DateTime nextPayDate = baseDate.add(Duration(days: daysUntilFirst));
    return nextPayDate.difference(nowDate).inDays;
  }

  if (paymentCycle == PaymentCycle.monthly) {
    DateTime nextPayDate = resolveMonthlyPaymentDate(
      baseDate.year,
      baseDate.month,
      preferredDay: paymentDate.day,
      isLastDayOfMonth: isLastDayOfMonth,
    );
    if (nextPayDate.isBefore(baseDate)) {
      int nextMonth = baseDate.month + 1;
      int nextYear = baseDate.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear += 1;
      }
      nextPayDate = resolveMonthlyPaymentDate(
        nextYear,
        nextMonth,
        preferredDay: paymentDate.day,
        isLastDayOfMonth: isLastDayOfMonth,
      );
    }
    return nextPayDate.difference(nowDate).inDays;
  }

  if (paymentCycle == PaymentCycle.yearly) {
    int month = paymentDate.month;
    int day = paymentDate.day;
    final lastDayThisYear = DateTime(baseDate.year, month + 1, 0).day;
    DateTime nextPayDate = DateTime(
      baseDate.year,
      month,
      day > lastDayThisYear ? lastDayThisYear : day,
    );
    if (nextPayDate.isBefore(baseDate)) {
      final nextYear = baseDate.year + 1;
      final lastDayNext = DateTime(nextYear, month + 1, 0).day;
      nextPayDate = DateTime(
        nextYear,
        month,
        day > lastDayNext ? lastDayNext : day,
      );
    }
    return nextPayDate.difference(nowDate).inDays;
  }

  return 9999;
}

int getServiceDDay(SubscriptionService service) {
  if (service.paymentDate == null || service.paymentCycle == null) return 9999;
  return getDDay(
    service.paymentDate!,
    service.paymentCycle!,
    service.paymentStartDate,
    isLastDayOfMonth: serviceIsLastDayOfMonth(service),
  );
}

List<DateTime> getFuturePaymentDates(SubscriptionService service) {
  final Set<DateTime> dates = {};
  final now = DateTime.now();
  final startDate = service.paymentStartDate;
  if (service.paymentDate == null || service.paymentCycle == null) {
    return dates.toList();
  }

  DateTime base = now.isBefore(startDate) ? startDate : now;

  if (service.paymentCycle == PaymentCycle.monthly) {
    for (int i = 0; i < 36; i++) {
      final year = base.year + ((base.month + i - 1) ~/ 12);
      final month = (base.month + i - 1) % 12 + 1;
      final date = resolveServiceMonthlyDate(service, year, month);
      if (!date.isBefore(startDate) && date.isAfter(now)) {
        dates.add(DateTime(date.year, date.month, date.day));
      }
    }
  } else if (service.paymentCycle == PaymentCycle.weekly) {
    DateTime date = base;
    int added = 0;
    while (added < 156) {
      if (date.weekday == service.paymentDate!.weekday &&
          !date.isBefore(startDate) &&
          date.isAfter(now)) {
        dates.add(DateTime(date.year, date.month, date.day));
        added++;
      }
      date = date.add(const Duration(days: 1));
      if (date.difference(now).inDays > 365 * 3) break;
    }
  } else if (service.paymentCycle == PaymentCycle.yearly) {
    for (int i = 0; i < 3; i++) {
      final year = base.year + i;
      final month = service.paymentDate!.month;
      final day = service.paymentDate!.day;
      final lastDay = DateTime(year, month + 1, 0).day;
      final date = DateTime(year, month, day > lastDay ? lastDay : day);
      if (!date.isBefore(startDate) && date.isAfter(now)) {
        dates.add(DateTime(date.year, date.month, date.day));
      }
    }
  }
  final sorted = dates.toList()..sort();
  return sorted;
}

List<DateTime> getFutureDdays(SubscriptionService service) {
  final Set<DateTime> dates = {};
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startDate = service.paymentStartDate;
  if (service.paymentDate == null || service.paymentCycle == null) {
    return dates.toList();
  }

  DateTime base = today.isBefore(startDate)
      ? DateTime(startDate.year, startDate.month, startDate.day)
      : today;

  if (service.paymentCycle == PaymentCycle.monthly) {
    for (int i = 0; i < 36; i++) {
      final year = base.year + ((base.month + i - 1) ~/ 12);
      final month = (base.month + i - 1) % 12 + 1;
      final date = resolveServiceMonthlyDate(service, year, month);
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (!dateOnly.isBefore(startDate) && !dateOnly.isBefore(today)) {
        dates.add(dateOnly);
      }
    }
  } else if (service.paymentCycle == PaymentCycle.weekly) {
    DateTime date = base;
    int added = 0;
    while (added < 156) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly.weekday == service.paymentDate!.weekday &&
          !dateOnly.isBefore(startDate) &&
          !dateOnly.isBefore(today)) {
        dates.add(dateOnly);
        added++;
      }
      date = date.add(const Duration(days: 1));
      if (date.difference(today).inDays > 365 * 3) break;
    }
  } else if (service.paymentCycle == PaymentCycle.yearly) {
    for (int i = 0; i < 3; i++) {
      final year = base.year + i;
      final month = service.paymentDate!.month;
      final day = service.paymentDate!.day;
      final lastDay = DateTime(year, month + 1, 0).day;
      final date = DateTime(year, month, day > lastDay ? lastDay : day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (!dateOnly.isBefore(startDate) && !dateOnly.isBefore(today)) {
        dates.add(dateOnly);
      }
    }
  }
  final sorted = dates.toList()..sort();
  return sorted;
}

List<DateTime> getFutureBeforeNotifyDates(SubscriptionService service) {
  final Set<DateTime> dates = {};
  final now = DateTime.now();
  final startDate = service.paymentStartDate;
  if (service.paymentDate == null || service.paymentCycle == null) {
    return dates.toList();
  }

  DateTime base = now.isBefore(startDate) ? startDate : now;

  if (service.paymentCycle == PaymentCycle.monthly) {
    for (int i = 0; i < 36; i++) {
      final year = base.year + ((base.month + i - 1) ~/ 12);
      final month = (base.month + i - 1) % 12 + 1;
      final date = resolveServiceMonthlyDate(service, year, month);
      final beforeDate = date.subtract(const Duration(days: 1));
      if (!beforeDate.isBefore(startDate) && beforeDate.isAfter(now)) {
        dates.add(DateTime(beforeDate.year, beforeDate.month, beforeDate.day));
      }
    }
  } else if (service.paymentCycle == PaymentCycle.weekly) {
    DateTime date = base;
    int added = 0;
    while (added < 156) {
      if (date.weekday == service.paymentDate!.weekday &&
          !date.isBefore(startDate) &&
          date.isAfter(now)) {
        final beforeDate = date.subtract(const Duration(days: 1));
        if (!beforeDate.isBefore(startDate) && beforeDate.isAfter(now)) {
          dates.add(
            DateTime(beforeDate.year, beforeDate.month, beforeDate.day),
          );
        }
        added++;
      }
      date = date.add(const Duration(days: 1));
      if (date.difference(now).inDays > 365 * 3) break;
    }
  } else if (service.paymentCycle == PaymentCycle.yearly) {
    for (int i = 0; i < 3; i++) {
      final year = base.year + i;
      final month = service.paymentDate!.month;
      final day = service.paymentDate!.day;
      final lastDay = DateTime(year, month + 1, 0).day;
      final date = DateTime(year, month, day > lastDay ? lastDay : day);
      final beforeDate = date.subtract(const Duration(days: 1));
      if (!beforeDate.isBefore(startDate) && beforeDate.isAfter(now)) {
        dates.add(DateTime(beforeDate.year, beforeDate.month, beforeDate.day));
      }
    }
  }
  final sorted = dates.toList()..sort();
  return sorted;
}
