import 'habit.dart';

abstract class HabitRepository {
  Future<List<HabitCategoryOption>> getCategories();

  /// All active habits with today's completion + streak already attached.
  Future<List<Habit>> getHabits();

  Future<Habit> createHabit({
    required String title,
    String? description,
    required String categoryKey,
    String? identityId,
    required String icon,
    required String color,
    required String frequencyType,
    Map<String, dynamic> frequencyConfig,
    List<String> reminderTimes,
    required String priority,
    double? targetValue,
    String? targetUnit,
  });

  Future<void> updateHabit(Habit habit);

  Future<void> archiveHabit(String habitId);

  Future<void> deleteHabit(String habitId);

  /// Toggles today's completion for a habit and returns the updated streak.
  Future<({int currentStreak, int longestStreak})> toggleCompletion({
    required String habitId,
    required DateTime date,
    double? value,
    String? note,
  });

  Future<List<HabitLog>> getLogs({
    required String habitId,
    required DateTime from,
    required DateTime to,
  });

  /// Completion rate (0-1) over the given number of past days, for stats.
  Future<double> getCompletionRate(String habitId, {int days = 30});
}
