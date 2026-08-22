import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_service.dart';
import '../../domain/habit.dart';

final _client = SupabaseService.client;

String get _userId {
  final id = SupabaseService.currentUser?.id;
  if (id == null) {
    throw StateError('No authenticated user.');
  }
  return id;
}

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  HabitsNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();

    try {
      final rows = await _client
          .from('habits')
          .select(
            '*, habit_categories(key), '
            'habit_streaks(current_streak, longest_streak)',
          )
          .eq('user_id', _userId)
          .eq('is_active', true)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      final today = DateTime.now().toIso8601String().split('T').first;

      final logs = await _client
          .from('habit_logs')
          .select('habit_id, completed')
          .eq('user_id', _userId)
          .eq('log_date', today);

      final completedToday = <String>{
        for (final log in logs)
          if (log['completed'] == true) log['habit_id'] as String,
      };

      final habits = (rows as List).map((row) {
        final map = Map<String, dynamic>.from(row);

        final category = map['habit_categories'];
        String categoryKey = 'custom';

        if (category is Map<String, dynamic>) {
          categoryKey = category['key'] as String? ?? 'custom';
        } else if (category is List && category.isNotEmpty) {
          final first = category.first;
          if (first is Map<String, dynamic>) {
            categoryKey = first['key'] as String? ?? 'custom';
          }
        }

        final streak = map['habit_streaks'];

        int currentStreak = 0;
        int longestStreak = 0;

        if (streak is Map<String, dynamic>) {
          currentStreak =
              (streak['current_streak'] as num?)?.toInt() ?? 0;
          longestStreak =
              (streak['longest_streak'] as num?)?.toInt() ?? 0;
        } else if (streak is List && streak.isNotEmpty) {
          final first = streak.first;

          if (first is Map<String, dynamic>) {
            currentStreak =
                (first['current_streak'] as num?)?.toInt() ?? 0;
            longestStreak =
                (first['longest_streak'] as num?)?.toInt() ?? 0;
          }
        }

        final habit = Habit.fromMap(
          map,
          categoryKey: categoryKey,
        );

        return habit.copyWith(
          completedToday: completedToday.contains(habit.id),
          currentStreak: currentStreak,
          longestStreak: longestStreak,
        );
      }).toList();

      state = AsyncValue.data(habits);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<String?> _categoryIdForKey(String key) async {
    final row = await _client
        .from('habit_categories')
        .select('id')
        .eq('key', key)
        .maybeSingle();

    return row?['id'] as String?;
  }

  Future<void> create({
    required String title,
    String? description,
    required String categoryKey,
    required Color color,
    required String frequencyType,
    int? timesPerWeek,
    required String priority,
  }) async {
    final categoryId = await _categoryIdForKey(categoryKey);

    final frequencyConfig = <String, dynamic>{};

    if (timesPerWeek != null) {
      frequencyConfig['times_per_week'] = timesPerWeek;
    }

    await _client.from('habits').insert({
      'user_id': _userId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'color': Habit.colorToHex(color),
      'frequency_type': frequencyType,
      'frequency_config': frequencyConfig,
      'priority': priority,
    });

    await refresh();
  }

  Future<void> update({
    required String habitId,
    required String title,
    String? description,
    required String categoryKey,
    required Color color,
    required String frequencyType,
    int? timesPerWeek,
    required String priority,
  }) async {
    final categoryId = await _categoryIdForKey(categoryKey);

    final frequencyConfig = <String, dynamic>{};

    if (timesPerWeek != null) {
      frequencyConfig['times_per_week'] = timesPerWeek;
    }

    await _client
        .from('habits')
        .update({
          'category_id': categoryId,
          'title': title,
          'description': description,
          'color': Habit.colorToHex(color),
          'frequency_type': frequencyType,
          'frequency_config': frequencyConfig,
          'priority': priority,
        })
        .eq('id', habitId);

    await refresh();
  }

  Future<void> toggleCompletion(
    String habitId,
    bool completed,
  ) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    await _client.from('habit_logs').upsert(
      {
        'habit_id': habitId,
        'user_id': _userId,
        'log_date': today,
        'completed': completed,
        'completed_at':
            completed ? DateTime.now().toIso8601String() : null,
      },
      onConflict: 'habit_id,log_date',
    );

    final streakRow = await _client
        .from('habit_streaks')
        .select()
        .eq('habit_id', habitId)
        .maybeSingle();

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;

    final lastCompleted =
        streakRow?['last_completed_date'] as String?;

    int currentStreak =
        (streakRow?['current_streak'] as num?)?.toInt() ?? 0;

    int longestStreak =
        (streakRow?['longest_streak'] as num?)?.toInt() ?? 0;

    if (completed) {
      currentStreak =
          lastCompleted == yesterday ? currentStreak + 1 : 1;

      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }

      await _client.from('habit_streaks').upsert({
        'habit_id': habitId,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_completed_date': today,
      });
    } else {
      await _client.from('habit_streaks').upsert({
        'habit_id': habitId,
        'current_streak': 0,
        'longest_streak': longestStreak,
        'last_completed_date': lastCompleted,
      });
    }

    await refresh();
  }

  Future<void> toggleToday(String habitId) async {
    final current = state.valueOrNull ?? [];

    final habit = current
        .where((habit) => habit.id == habitId)
        .firstOrNull;

    final newState = !(habit?.completedToday ?? false);

    await toggleCompletion(habitId, newState);
  }

  Future<void> archive(String habitId) async {
    await _client
        .from('habits')
        .update({'is_active': false})
        .eq('id', habitId);

    await refresh();
  }

  Future<void> delete(String habitId) async {
    await _client
        .from('habits')
        .update({'is_active': false})
        .eq('id', habitId);

    await refresh();
  }
}

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>(
  (ref) => HabitsNotifier(),
);

final todayPendingHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull ?? [];

  return habits
      .where((habit) => !habit.completedToday)
      .toList();
});
