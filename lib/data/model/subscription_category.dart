class SubscriptionCategory {
  final String id;
  final String name;
  final int? colorValue; // Color를 DB에 저장할 때는 int로 변환

  SubscriptionCategory({
    required this.id,
    required this.name,
    this.colorValue,
  });

  SubscriptionCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
  }) {
    return SubscriptionCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
    };
  }

  factory SubscriptionCategory.fromMap(Map<String, dynamic> map) {
    return SubscriptionCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int?,
    );
  }
}