import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_habit_repository.dart';
import '../../domain/habit.dart';
import '../../domain/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return SupabaseHabitRepository();
});

final habitCategoriesProvider = FutureProvider<List<HabitCategoryOption>>((ref) {
  return ref.watch(habitRepositoryProvider).getCategories();
});

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() {
    return ref.watch(habitRepositoryProvider).getHabits();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(habitRepositoryProvider).getHabits());
  }

  Future<void> toggleToday(String habitId) async {
    final repo = ref.read(habitRepositoryProvider);
    final current = state.valueOrNull ?? [];

    // Optimistic update so the UI feels instant.
    state = AsyncData([
      for (final h in current)
        if (h.id == habitId) h.copyWith(completedToday: !h.completedToday) else h,
    ]);

    try {
      final result = await repo.toggleCompletion(habitId: habitId, date: DateTime.now());
      final updated = state.valueOrNull ?? [];
      state = AsyncData([
        for (final h in updated)
          if (h.id == habitId)
            h.copyWith(currentStreak: result.currentStreak, longestStreak: result.longestStreak)
          else
            h,
      ]);
    } catch (_) {
      // Roll back on failure.
      state = AsyncData(current);
    }
  }

  Future<void> addHabit({
    required String title,
    String? description,
    required String categoryKey,
    String? identityId,
    required String icon,
    required String color,
    required String frequencyType,
    Map<String, dynamic> frequencyConfig = const {},
    List<String> reminderTimes = const [],
    required String priority,
    double? targetValue,
    String? targetUnit,
  }) async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.createHabit(
      title: title,
      description: description,
      categoryKey: categoryKey,
      identityId: identityId,
      icon: icon,
      color: color,
      frequencyType: frequencyType,
      frequencyConfig: frequencyConfig,
      reminderTimes: reminderTimes,
      priority: priority,
      targetValue: targetValue,
      targetUnit: targetUnit,
    );
    await refresh();
  }

  Future<void> archive(String habitId) async {
    await ref.read(habitRepositoryProvider).archiveHabit(habitId);
    await refresh();
  }

  Future<void> delete(String habitId) async {
    await ref.read(habitRepositoryProvider).deleteHabit(habitId);
    await refresh();
  }
}

final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

/// Habits not yet completed today, sorted by priority — used on Home.
final todayPendingHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull ?? [];
  return habits.where((h) => !h.completedToday).toList();
});

/// 0.0–1.0 fraction of today's habits completed — used for Home progress ring.
final todayCompletionRateProvider = Provider<double>((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull ?? [];
  if (habits.isEmpty) return 0;
  final done = habits.where((h) => h.completedToday).length;
  return done / habits.length;
});
