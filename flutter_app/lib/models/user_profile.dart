class UserProfile {
  final String userId;
  final String displayName;
  final String email;
  final String country;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    this.country = 'Chile',
    this.currency = 'CLP',
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? country,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    country: country ?? this.country,
    currency: currency ?? this.currency,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
