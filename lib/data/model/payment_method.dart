class PaymentMethod {
  final String id;
  final String? serviceName;
  final String alias;
  final String memo;

  PaymentMethod({
    required this.id,
    this.serviceName,
    required this.alias,
    required this.memo,
  });

  PaymentMethod copyWith({
    String? id,
    String? serviceName,
    String? alias,
    String? memo,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      alias: alias ?? this.alias,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceName': serviceName,
      'alias': alias,
      'memo': memo,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as String,
      serviceName: map['serviceName'] as String?,
      alias: map['alias'] as String,
      memo: map['memo'] as String,
    );
  }
}
