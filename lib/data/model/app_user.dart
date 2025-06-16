class AppUser {
  final bool isPremium;
  final String createdAt;
  final String deviceId;

  AppUser({
    required this.isPremium,
    required this.createdAt,
    required this.deviceId,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      isPremium: map['isPremium'] as bool? ?? false,
      createdAt: map['createdAt'] as String? ?? '',
      deviceId: map['deviceId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPremium': isPremium,
      'createdAt': createdAt,
      'deviceId': deviceId,
    };
  }
}
