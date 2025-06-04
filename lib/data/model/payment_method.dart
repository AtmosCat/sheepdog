import 'dart:math';

class PaymentMethod {
  final String id;
  final String? serviceName;
  final String? logoUrl;
  final String alias;
  final String memo;

  PaymentMethod({
    String? id,
    this.serviceName,
    this.logoUrl,
    required this.alias,
    required this.memo,
  }) : id = id ?? generateRandomId();

  PaymentMethod copyWith({
    String? id,
    String? serviceName,
    String? logoUrl,
    String? alias,
    String? memo,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      logoUrl: logoUrl ?? this.logoUrl,
      alias: alias ?? this.alias,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceName': serviceName,
      'logoUrl': logoUrl,
      'alias': alias,
      'memo': memo,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as String,
      serviceName: map['serviceName'] as String?,
      logoUrl: map['logoUrl'] as String?,
      alias: map['alias'] as String,
      memo: map['memo'] as String,
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
