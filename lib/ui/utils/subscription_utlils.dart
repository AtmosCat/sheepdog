import 'package:intl/intl.dart';
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

/// D-day 계산
int getDDay(DateTime? paymentDate, PaymentCycle? paymentCycle) {
  if (paymentDate == null || paymentCycle == null) return 9999;
  final now = DateTime.now();
  final nowDate = DateTime(now.year, now.month, now.day);
  final payDate = DateTime(paymentDate.year, paymentDate.month, paymentDate.day);
  final diff = payDate.difference(nowDate).inDays;
  if (diff >= 0) return diff;

  // 결제일이 지났으면 다음 결제일까지 남은 일수 계산
  if (paymentCycle == PaymentCycle.monthly) {
    int nextMonth = payDate.month + 1;
    int nextYear = payDate.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }
    DateTime nextPayDate;
    try {
      nextPayDate = DateTime(nextYear, nextMonth, payDate.day);
    } catch (_) {
      final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
      nextPayDate = DateTime(nextYear, nextMonth, lastDay);
    }
    return nextPayDate.difference(nowDate).inDays;
  } else if (paymentCycle == PaymentCycle.yearly) {
    int nextYear = payDate.year + 1;
    DateTime nextPayDate;
    try {
      nextPayDate = DateTime(nextYear, payDate.month, payDate.day);
    } catch (_) {
      final lastDay = DateTime(nextYear, payDate.month + 1, 0).day;
      nextPayDate = DateTime(nextYear, payDate.month, lastDay);
    }
    return nextPayDate.difference(nowDate).inDays;
  } else if (paymentCycle == PaymentCycle.weekly) {
    int currentWeekday = nowDate.weekday;
    int payWeekday = payDate.weekday;
    int daysUntilNext = (payWeekday - currentWeekday) % 7;
    if (daysUntilNext <= 0) daysUntilNext += 7;
    return daysUntilNext;
  }
  return 9999;
}
