class HabitCategoryOption {
  final String id;
  final String key;
  final String label;
  final String icon;
  final String color;

  const HabitCategoryOption({
    required this.id,
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  factory HabitCategoryOption.fromMap(Map<String, dynamic> map) => HabitCategoryOption(
        id: map['id'] as String,
        key: map['key'] as String,
        label: map['label'] as String,
        icon: map['icon'] as String? ?? 'star',
        color: map['color'] as String? ?? '#64748B',
      );
}

class Habit {
  final String id;
  final String userId;
  final String? identityId;
  final String? categoryId;
  final String categoryKey; // denormalized for display without a join
  final String title;
  final String? description;
  final String icon;
  final String color;
  final String frequencyType; // daily | weekly | custom_days | x_times_per_week
  final Map<String, dynamic> frequencyConfig;
  final List<String> reminderTimes; // 'HH:mm'
  final String priority; // low | medium | high
  final double? targetValue;
  final String? targetUnit;
  final bool isActive;
  final DateTime createdAt;

  // Joined/derived — populated by the repository, not stored directly here.
  final bool completedToday;
  final int currentStreak;
  final int longestStreak;

  const Habit({
    required this.id,
    required this.userId,
    this.identityId,
    this.categoryId,
    required this.categoryKey,
    required this.title,
    this.description,
    this.icon = 'star',
    this.color = '#2563EB',
    required this.frequencyType,
    this.frequencyConfig = const {},
    this.reminderTimes = const [],
    this.priority = 'medium',
    this.targetValue,
    this.targetUnit,
    this.isActive = true,
    required this.createdAt,
    this.completedToday = false,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  factory Habit.fromMap(Map<String, dynamic> map, {String categoryKey = 'custom'}) {
    return Habit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      identityId: map['identity_id'] as String?,
      categoryId: map['category_id'] as String?,
      categoryKey: categoryKey,
      title: map['title'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String? ?? 'star',
      color: map['color'] as String? ?? '#2563EB',
      frequencyType: map['frequency_type'] as String,
      frequencyConfig: (map['frequency_config'] as Map<String, dynamic>?) ?? {},
      reminderTimes: (map['reminder_times'] as List<dynamic>?)?.cast<String>() ?? [],
      priority: map['priority'] as String? ?? 'medium',
      targetValue: (map['target_value'] as num?)?.toDouble(),
      targetUnit: map['target_unit'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Habit copyWith({
    bool? completedToday,
    int? currentStreak,
    int? longestStreak,
  }) {
    return Habit(
      id: id,
      userId: userId,
      identityId: identityId,
      categoryId: categoryId,
      categoryKey: categoryKey,
      title: title,
      description: description,
      icon: icon,
      color: color,
      frequencyType: frequencyType,
      frequencyConfig: frequencyConfig,
      reminderTimes: reminderTimes,
      priority: priority,
      targetValue: targetValue,
      targetUnit: targetUnit,
      isActive: isActive,
      createdAt: createdAt,
      completedToday: completedToday ?? this.completedToday,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
}

class HabitLog {
  final String id;
  final String habitId;
  final DateTime logDate;
  final bool completed;
  final double? value;
  final String? note;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.logDate,
    required this.completed,
    this.value,
    this.note,
  });

  factory HabitLog.fromMap(Map<String, dynamic> map) => HabitLog(
        id: map['id'] as String,
        habitId: map['habit_id'] as String,
        logDate: DateTime.parse(map['log_date'] as String),
        completed: map['completed'] as bool? ?? false,
        value: (map['value'] as num?)?.toDouble(),
        note: map['note'] as String?,
      );
}
