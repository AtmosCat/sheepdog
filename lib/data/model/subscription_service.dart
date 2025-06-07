import 'dart:math';

enum PaymentCycle { yearly, monthly, weekly }

class SubscriptionService {
  final String id;
  final String name;
  final String? logoUrl;
  final String? emoji;
  final String categoryId;
  final PaymentCycle? paymentCycle;
  final DateTime? paymentDate;
  final int? paymentAmount;
  final String? paymentMethodId; // <- 필수 아님 (nullable)
  final String memo;
  final DateTime? createdAt;

  SubscriptionService({
    String? id,
    required this.name,
    this.logoUrl,
    this.emoji,
    required this.categoryId,
    this.paymentCycle,
    this.paymentDate,
    this.paymentAmount,
    this.paymentMethodId, // <- nullable
    required this.memo,
    this.createdAt,
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
      'paymentMethodId': paymentMethodId, // <- nullable
      'memo': memo,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory SubscriptionService.fromMap(Map<String, dynamic> map) {
    return SubscriptionService(
      id: map['id'] as String,
      name: map['name'] as String,
      logoUrl: map['logoUrl'] as String?,
      emoji: map['emoji'] as String?,
      categoryId: map['categoryId'] as String,
      paymentCycle: map['paymentCycle'] != null
          ? PaymentCycle.values[map['paymentCycle'] as int]
          : null,
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate'])
          : null,
      paymentAmount: map['paymentAmount'] as int?,
      paymentMethodId: map['paymentMethodId'] as String?, // <- nullable
      memo: map['memo'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
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
