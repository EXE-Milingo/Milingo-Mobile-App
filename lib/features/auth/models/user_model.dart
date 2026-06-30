/// User model representing authenticated user data
class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    this.displayName,
    this.photoUrl,
    this.preferredLanguage = 'vi',
    this.miLingoCoins = 0,
    this.dailyStreak = 0,
    this.lastActiveDate,
    this.isPremium = false,
  });

  /// Create from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'vi',
      miLingoCoins: json['milingo_coins'] as int? ?? 0,
      dailyStreak: json['daily_streak'] as int? ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.parse(json['last_active_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String preferredLanguage; // Learning language
  final int miLingoCoins;
  final int dailyStreak;
  final DateTime? lastActiveDate;
  final DateTime createdAt;
  final bool isPremium;

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'preferred_language': preferredLanguage,
      'milingo_coins': miLingoCoins,
      'daily_streak': dailyStreak,
      'last_active_date': lastActiveDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_premium': isPremium,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? preferredLanguage,
    int? miLingoCoins,
    int? dailyStreak,
    DateTime? lastActiveDate,
    DateTime? createdAt,
    bool? isPremium,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      miLingoCoins: miLingoCoins ?? this.miLingoCoins,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  /// Check if user should get streak bonus today
  bool shouldUpdateStreak() {
    if (lastActiveDate == null) return true;
    final now = DateTime.now();
    final lastActive = lastActiveDate!;

    // Compare calendar dates (midnight of each day)
    final today = DateTime(now.year, now.month, now.day);
    final lastActiveDay =
        DateTime(lastActive.year, lastActive.month, lastActive.day);

    // Update if last active day was before today
    return lastActiveDay.isBefore(today);
  }

  /// Check if streak should be reset
  bool shouldResetStreak() {
    if (lastActiveDate == null) return false;
    final now = DateTime.now();
    final lastActive = lastActiveDate!;

    // Compare calendar dates (midnight of each day)
    final today = DateTime(now.year, now.month, now.day);
    final lastActiveDay =
        DateTime(lastActive.year, lastActive.month, lastActive.day);

    // Reset if the last active day was before yesterday (meaning they missed yesterday entirely)
    final yesterday = today.subtract(const Duration(days: 1));
    return lastActiveDay.isBefore(yesterday);
  }
}
