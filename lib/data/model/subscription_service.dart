import 'dart:math';

enum PaymentCycle { yearly, monthly, weekly }

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
    required this.paymentStartDate, // 필수 파라미터로 추가
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
    DateTime? paymentStartDate, // 추가
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
      paymentStartDate: paymentStartDate ?? this.paymentStartDate, // 추가
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
      'paymentStartDate': paymentStartDate.toIso8601String(), // 필수
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
          ? DateTime.tryParse(map['paymentDate'])
          : null,
      paymentAmount: map['paymentAmount'] as int?,
      paymentMethodId: map['paymentMethodId'] as String?,
      memo: map['memo'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
      paymentStartDate: DateTime.parse(map['paymentStartDate']), // 필수
    );
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
