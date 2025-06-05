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
  final String paymentMethodId;
  final String memo;
  final DateTime? createdAt; // 추가된 부분

  SubscriptionService({
    String? id,
    required this.name,
    this.logoUrl,
    this.emoji,
    required this.categoryId,
    this.paymentCycle,
    this.paymentDate,
    this.paymentAmount,
    required this.paymentMethodId,
    required this.memo,
    this.createdAt, // 추가된 부분
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
    DateTime? createdAt, // 추가된 부분
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
      createdAt: createdAt ?? this.createdAt, // 추가된 부분
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
      'createdAt': createdAt?.toIso8601String(), // 추가된 부분
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
      paymentMethodId: map['paymentMethodId'] as String,
      memo: map['memo'] as String,
      createdAt:
          map['createdAt'] !=
              null // 추가된 부분
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
