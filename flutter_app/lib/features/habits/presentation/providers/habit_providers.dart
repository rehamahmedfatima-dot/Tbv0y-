import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/habit.dart';

final _client = SupabaseService.client;
String get _userId => SupabaseService.currentUser!.id;

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  HabitsNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final rows = await _client
          .from('habits')
          .select('*, habit_categories(key), habit_streaks(current_streak, longest_streak)')
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
      final completedToday = {
        for (final l in logs as List)
          if (l['completed'] == true) l['habit_id'] as String,
      };

      final habits = (rows as List).map((r) {
        final habit = Habit.fromJson(r);
        return Habit(
          id: habit.id,
          userId: habit.userId,
          identityId: habit.identityId,
          categoryId: habit.categoryId,
          categoryKey: habit.categoryKey,
          title: habit.title,
          description: habit.description,
          icon: habit.icon,
          color: habit.color,
          frequencyConfig: habit.frequencyConfig,
          priority: habit.priority,
          targetValue: habit.targetValue,
          targetUnit: habit.targetUnit,
          isActive: habit.isActive,
          createdAt: habit.createdAt,
          currentStreak: habit.currentStreak,
          longestStreak: habit.longestStreak,
          completedToday: completedToday.contains(habit.id),
        );
      }).toList();

      state = AsyncValue.data(habits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> _categoryIdForKey(String key) async {
    final row = await _client.from('habit_categories').select('id').eq('key', key).maybeSingle();
    return row?['id'] as String?;
  }

  Future<void> create({
    required String title,
    String? description,
    required String categoryKey,
    required Color color,
    required HabitFrequencyType frequencyType,
    int? timesPerWeek,
    required HabitPriority priority,
  }) async {
    final categoryId = await _categoryIdForKey(categoryKey);

    await _client.from('habits').insert({
      'user_id': _userId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'color': Habit.colorToHex(color),
      'frequency_type': frequencyToString(frequencyType),
      'frequency_config': timesPerWeek != null ? {'times_per_week': timesPerWeek} : {},
      'priority': priority.name,
    });

    await refresh();
  }

  Future<void> update({
    required String habitId,
    required String title,
    String? description,
    required String categoryKey,
    required Color color,
    required HabitFrequencyType frequencyType,
    int? timesPerWeek,
    required HabitPriority priority,
  }) async {
    final categoryId = await _categoryIdForKey(categoryKey);

    await _client.from('habits').update({
      'category_id': categoryId,
      'title': title,
      'description': description,
      'color': Habit.colorToHex(color),
      'frequency_type': frequencyToString(frequencyType),
      'frequency_config': timesPerWeek != null ? {'times_per_week': timesPerWeek} : {},
      'priority': priority.name,
    }).eq('id', habitId);

    await refresh();
  }

  Future<void> toggleCompletion(String habitId, bool completed) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    await _client.from('habit_logs').upsert({
      'habit_id': habitId,
      'user_id': _userId,
      'log_date': today,
      'completed': completed,
      'completed_at': completed ? DateTime.now().toIso8601String() : null,
    }, onConflict: 'habit_id,log_date');

    // Recompute streak
    final streakRow =
        await _client.from('habit_streaks').select().eq('habit_id', habitId).maybeSingle();
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T').first;
    final lastCompleted = streakRow?['last_completed_date'] as String?;

    int currentStreak = streakRow?['current_streak'] as int? ?? 0;
    int longestStreak = streakRow?['longest_streak'] as int? ?? 0;

    if (completed) {
      currentStreak = (lastCompleted == yesterday) ? currentStreak + 1 : 1;
      if (currentStreak > longestStreak) longestStreak = currentStreak;
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

  Future<void> delete(String habitId) async {
    await _client.from('habits').update({'is_active': false}).eq('id', habitId);
    await refresh();
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>(
  (ref) => HabitsNotifier(),
);
