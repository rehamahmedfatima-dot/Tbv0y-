class Achievement {
  final String id;
  final String key;
  final String title;
  final String? description;
  final String? category;
  final String icon;
  final int xpReward;
  final bool unlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.key,
    required this.title,
    this.description,
    this.category,
    required this.icon,
    required this.xpReward,
    this.unlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json, {bool unlocked = false, DateTime? unlockedAt}) =>
      Achievement(
        id: json['id'] as String,
        key: json['key'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
        icon: json['icon'] as String? ?? 'star',
        xpReward: json['xp_reward'] as int? ?? 0,
        unlocked: unlocked,
        unlockedAt: unlockedAt,
      );
}

class UserLevel {
  final int xp;
  final int level;

  const UserLevel({required this.xp, required this.level});

  /// XP needed to reach the next level, using the same curve as the
  /// backend (100 * level^1.3, rounded).
  int get xpForNextLevel => (100 * (level + 1) * 1.3).round();
  int get xpForCurrentLevel => (100 * level * 1.3).round();
  double get progressToNextLevel {
    final span = xpForNextLevel - xpForCurrentLevel;
    if (span <= 0) return 1;
    return ((xp - xpForCurrentLevel) / span).clamp(0, 1).toDouble();
  }

  factory UserLevel.fromJson(Map<String, dynamic> json) =>
      UserLevel(xp: json['xp'] as int? ?? 0, level: json['level'] as int? ?? 1);
}
