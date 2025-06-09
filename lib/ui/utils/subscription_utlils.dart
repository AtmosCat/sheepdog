import 'package:sheepdog/data/model/subscription_service.dart';

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

/// 결제일 텍스트 변환 (카드, 리스트 등에서 사용)
String paymentDateText(SubscriptionService item) {
  if (item.paymentCycle == PaymentCycle.yearly && item.paymentDate != null) {
    return '${item.paymentDate!.month}월 ${item.paymentDate!.day}일';
  }
  if (item.paymentCycle == PaymentCycle.monthly && item.paymentDate != null) {
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
    final day = service.paymentDate!.day;
    final date = DateTime(month.year, month.month, day);
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
      final date = DateTime(month.year, monthMatch, day);
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
  DateTime startDate, // "시작일" (필수)
) {
  final now = DateTime.now();
  final nowDate = DateTime(now.year, now.month, now.day);
  final start = DateTime(startDate.year, startDate.month, startDate.day);

  // 기준일: 오늘과 시작일 중 더 늦은 날짜
  final baseDate = nowDate.isBefore(start) ? start : nowDate;

  if (paymentCycle == PaymentCycle.weekly) {
    // 시작일 이후 첫 결제 요일 구하기
    int targetWeekday = paymentDate.weekday;
    int daysUntilFirst = (targetWeekday - baseDate.weekday) % 7;
    if (daysUntilFirst < 0) daysUntilFirst += 7;
    // 만약 기준일이 바로 결제 요일이면 daysUntilFirst == 0
    DateTime nextPayDate = baseDate.add(Duration(days: daysUntilFirst));
    return nextPayDate.difference(nowDate).inDays;
  }

  if (paymentCycle == PaymentCycle.monthly) {
    int day = paymentDate.day;
    DateTime nextPayDate;
    // 기준월의 결제일
    try {
      nextPayDate = DateTime(baseDate.year, baseDate.month, day);
    } catch (_) {
      // 말일 보정
      final lastDay = DateTime(baseDate.year, baseDate.month + 1, 0).day;
      nextPayDate = DateTime(baseDate.year, baseDate.month, lastDay);
    }
    // 기준일보다 결제일이 전이면 다음 달로
    if (nextPayDate.isBefore(baseDate)) {
      int nextMonth = baseDate.month + 1;
      int nextYear = baseDate.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear += 1;
      }
      try {
        nextPayDate = DateTime(nextYear, nextMonth, day);
      } catch (_) {
        final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        nextPayDate = DateTime(nextYear, nextMonth, lastDay);
      }
    }
    return nextPayDate.difference(nowDate).inDays;
  }

  if (paymentCycle == PaymentCycle.yearly) {
    int month = paymentDate.month;
    int day = paymentDate.day;
    DateTime nextPayDate;
    try {
      nextPayDate = DateTime(baseDate.year, month, day);
    } catch (_) {
      final lastDay = DateTime(baseDate.year, month + 1, 0).day;
      nextPayDate = DateTime(baseDate.year, month, lastDay);
    }
    if (nextPayDate.isBefore(baseDate)) {
      int nextYear = baseDate.year + 1;
      try {
        nextPayDate = DateTime(nextYear, month, day);
      } catch (_) {
        final lastDay = DateTime(nextYear, month + 1, 0).day;
        nextPayDate = DateTime(nextYear, month, lastDay);
      }
    }
    return nextPayDate.difference(nowDate).inDays;
  }

  return 9999;
}
