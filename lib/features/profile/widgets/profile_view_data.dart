class ProfileViewData {
  const ProfileViewData({
    required this.displayName,
    required this.email,
    required this.memberSince,
    required this.isPremium,
    required this.currentStreak,
    required this.coins,
    required this.totalPoints,
    required this.wordsLearned,
    this.photoUrl,
    this.localAvatarPath,
    this.premiumPlanName,
    this.premiumExpiresAt,
  });

  final String displayName;
  final String email;
  final String memberSince;
  final bool isPremium;
  final int currentStreak;
  final int coins;
  final int totalPoints;
  final int wordsLearned;
  final String? photoUrl;
  final String? localAvatarPath;
  final String? premiumPlanName;
  final DateTime? premiumExpiresAt;
}

class ProfileSettingsItemData {
  const ProfileSettingsItemData({
    required this.label,
    required this.assetPath,
    this.onTap,
  });

  final String label;
  final String assetPath;
  final void Function()? onTap;
}
