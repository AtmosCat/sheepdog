import 'dart:math';

class PaymentMethod {
  final String id;
  final String? serviceName;
  final String? logoUrl;
  final String alias;
  final String memo;
  final DateTime? createdAt; // 추가된 부분

  PaymentMethod({
    String? id,
    this.serviceName,
    this.logoUrl,
    required this.alias,
    required this.memo,
    this.createdAt, // 추가된 부분
  }) : id = id ?? generateRandomId();

  PaymentMethod copyWith({
    String? id,
    String? serviceName,
    String? logoUrl,
    String? alias,
    String? memo,
    DateTime? createdAt, // 추가된 부분
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      logoUrl: logoUrl ?? this.logoUrl,
      alias: alias ?? this.alias,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt, // 추가된 부분
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceName': serviceName,
      'logoUrl': logoUrl,
      'alias': alias,
      'memo': memo,
      'createdAt': createdAt?.toIso8601String(), // 추가된 부분
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as String,
      serviceName: map['serviceName'] as String?,
      logoUrl: map['logoUrl'] as String?,
      alias: map['alias'] as String,
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
