import 'dart:math';

enum PaymentCycle { yearly, monthly, weekly }

/// 매월 결제일의 '말일' 선택값 (UI/저장용 센티널)
const int kLastDayOfMonth = 0;

class SubscriptionService {
  final String id;
  final String name;
  final String? logoUrl;
  final String? emoji;
  final String? categoryId;
  final PaymentCycle? paymentCycle;
  final DateTime? paymentDate;
  final int? paymentAmount;
  final String? paymentMethodId;
  final String memo;
  final DateTime? createdAt;
  final DateTime paymentStartDate; // 결제 시작일 (필수)
  /// 매월 말일 결제 여부 (달이 28~31일로 달라도 해당 월의 마지막 날로 처리)
  final bool isLastDayOfMonth;
  /// 결제 금액이 정해지지 않은 경우 true (paymentAmount는 null)
  final bool isAmountUndetermined;

  SubscriptionService({
    String? id,
    required this.name,
    this.logoUrl,
    this.emoji,
    this.categoryId,
    this.paymentCycle,
    this.paymentDate,
    this.paymentAmount,
    this.paymentMethodId,
    required this.memo,
    this.createdAt,
    required this.paymentStartDate,
    this.isLastDayOfMonth = false,
    this.isAmountUndetermined = false,
  }) : id = id ?? generateRandomId();

  SubscriptionService copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? emoji,
    String? categoryId,
    PaymentCycle? paymentCycle,
    DateTime? paymentDate,
    int? paymentAmount,
    String? paymentMethodId,
    String? memo,
    DateTime? createdAt,
    DateTime? paymentStartDate,
    bool? isLastDayOfMonth,
    bool? isAmountUndetermined,
  }) {
    return SubscriptionService(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      emoji: emoji ?? this.emoji,
      categoryId: categoryId ?? this.categoryId,
      paymentCycle: paymentCycle ?? this.paymentCycle,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      paymentStartDate: paymentStartDate ?? this.paymentStartDate,
      isLastDayOfMonth: isLastDayOfMonth ?? this.isLastDayOfMonth,
      isAmountUndetermined:
          isAmountUndetermined ?? this.isAmountUndetermined,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'emoji': emoji,
      'categoryId': categoryId,
      'paymentCycle': paymentCycle?.index,
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentAmount': paymentAmount,
      'paymentMethodId': paymentMethodId,
      'memo': memo,
      'createdAt': createdAt?.toIso8601String(),
      'paymentStartDate': paymentStartDate.toIso8601String(),
      'isLastDayOfMonth': isLastDayOfMonth ? 1 : 0,
      'isAmountUndetermined': isAmountUndetermined ? 1 : 0,
    };
  }

  factory SubscriptionService.fromMap(Map<String, dynamic> map) {
    return SubscriptionService(
      id: map['id'] as String,
      name: map['name'] as String,
      logoUrl: map['logoUrl'] as String?,
      emoji: map['emoji'] as String?,
      categoryId: map['categoryId'] as String?,
      paymentCycle: map['paymentCycle'] != null
          ? PaymentCycle.values[map['paymentCycle'] as int]
          : null,
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate'] as String)
          : null,
      paymentAmount: map['paymentAmount'] as int?,
      paymentMethodId: map['paymentMethodId'] as String?,
      memo: map['memo'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      paymentStartDate: DateTime.parse(map['paymentStartDate'] as String),
      isLastDayOfMonth: _boolFromMap(map, 'isLastDayOfMonth'),
      isAmountUndetermined: _boolFromMap(map, 'isAmountUndetermined'),
    );
  }

  static bool _boolFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }
}

String generateRandomId({int length = 12}) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random();
  return List.generate(
    length,
    (index) => chars[rand.nextInt(chars.length)],
  ).join();
}
