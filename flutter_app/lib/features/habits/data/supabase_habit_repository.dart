import '../../../core/network/supabase_service.dart';
import '../domain/habit.dart';
import '../domain/habit_repository.dart';

class SupabaseHabitRepository implements HabitRepository {
  final _client = SupabaseService.client;

  String get _userId {
    final id = SupabaseService.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  String _today() => DateTime.now().toIso8601String().split('T').first;
  String _dateStr(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<List<HabitCategoryOption>> getCategories() async {
    final rows = await _client.from('habit_categories').select().order('label');
    return rows.map((r) => HabitCategoryOption.fromMap(r)).toList();
  }

  @override
  Future<List<Habit>> getHabits() async {
    final categories = await getCategories();
    final categoryKeyById = {for (final c in categories) c.id: c.key};

    final habitRows = await _client
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .order('priority', ascending: false)
        .order('created_at');

    if (habitRows.isEmpty) return [];

    final habitIds = habitRows.map((h) => h['id'] as String).toList();

    // Today's completion, in one query.
    final todayLogs = await _client
        .from('habit_logs')
        .select('habit_id, completed')
        .inFilter('habit_id', habitIds)
        .eq('log_date', _today());
    final completedTodayByHabit = {
      for (final l in todayLogs)
        if (l['completed'] == true) l['habit_id'] as String: true,
    };

    // Streaks, in one query.
    final streakRows =
        await _client.from('habit_streaks').select().inFilter('habit_id', habitIds);
    final streakByHabit = {
      for (final s in streakRows)
        s['habit_id'] as String: (current: s['current_streak'] as int? ?? 0, longest: s['longest_streak'] as int? ?? 0),
    };

    return habitRows.map((row) {
      final id = row['id'] as String;
      final categoryId = row['category_id'] as String?;
      final habit = Habit.fromMap(row, categoryKey: categoryKeyById[categoryId] ?? 'custom');
      final streak = streakByHabit[id];
      return habit.copyWith(
        completedToday: completedTodayByHabit[id] ?? false,
        currentStreak: streak?.current ?? 0,
        longestStreak: streak?.longest ?? 0,
      );
    }).toList();
  }

  @override
  Future<Habit> createHabit({
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
    final categories = await getCategories();
    final category = categories.firstWhere(
      (c) => c.key == categoryKey,
      orElse: () => categories.firstWhere((c) => c.key == 'custom'),
    );

    final inserted = await _client
        .from('habits')
        .insert({
          'user_id': _userId,
          'identity_id': identityId,
          'category_id': category.id,
          'title': title,
          'description': description,
          'icon': icon,
          'color': color,
          'frequency_type': frequencyType,
          'frequency_config': frequencyConfig,
          'reminder_times': reminderTimes,
          'priority': priority,
          'target_value': targetValue,
          'target_unit': targetUnit,
        })
        .select()
        .single();

    await _client.from('habit_streaks').insert({'habit_id': inserted['id']});

    return Habit.fromMap(inserted, categoryKey: category.key);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    await _client.from('habits').update({
      'title': habit.title,
      'description': habit.description,
      'icon': habit.icon,
      'color': habit.color,
      'frequency_type': habit.frequencyType,
      'frequency_config': habit.frequencyConfig,
      'reminder_times': habit.reminderTimes,
      'priority': habit.priority,
      'target_value': habit.targetValue,
      'target_unit': habit.targetUnit,
    }).eq('id', habit.id);
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    await _client
        .from('habits')
        .update({'is_active': false, 'archived_at': DateTime.now().toIso8601String()}).eq(
            'id', habitId);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _client.from('habits').delete().eq('id', habitId);
  }

  @override
  Future<({int currentStreak, int longestStreak})> toggleCompletion({
    required String habitId,
    required DateTime date,
    double? value,
    String? note,
  }) async {
    final dateStr = _dateStr(date);

    final existing = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .eq('log_date', dateStr)
        .maybeSingle();

    final willBeCompleted = existing == null || existing['completed'] != true;

    await _client.from('habit_logs').upsert({
      'habit_id': habitId,
      'user_id': _userId,
      'log_date': dateStr,
      'completed': willBeCompleted,
      'value': value,
      'note': note,
      'completed_at': willBeCompleted ? DateTime.now().toIso8601String() : null,
    }, onConflict: 'habit_id,log_date');

    return _recalculateStreak(habitId);
  }

  /// Recomputes current/longest streak from the log history and persists
  /// it to habit_streaks. Simple and correct beats a clever incremental
  /// update that can drift out of sync after edits/deletes.
  Future<({int currentStreak, int longestStreak})> _recalculateStreak(String habitId) async {
    final logs = await _client
        .from('habit_logs')
        .select('log_date, completed')
        .eq('habit_id', habitId)
        .eq('completed', true)
        .order('log_date', ascending: false);

    if (logs.isEmpty) {
      await _client.from('habit_streaks').upsert({
        'habit_id': habitId,
        'current_streak': 0,
        'longest_streak': 0,
        'last_completed_date': null,
      });
      return (currentStreak: 0, longestStreak: 0);
    }

    final dates = logs.map((l) => DateTime.parse(l['log_date'] as String)).toList();

    int longest = 1;
    int running = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i - 1].difference(dates[i]).inDays;
      if (diff == 1) {
        running++;
      } else if (diff > 1) {
        running = 1;
      }
      if (running > longest) longest = running;
    }

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final mostRecent = dates.first;
    final gapFromToday = todayMidnight.difference(mostRecent).inDays;

    int current = 0;
    if (gapFromToday <= 1) {
      current = 1;
      for (int i = 1; i < dates.length; i++) {
        if (dates[i - 1].difference(dates[i]).inDays == 1) {
          current++;
        } else {
          break;
        }
      }
    }

    final previousStreakRow =
        await _client.from('habit_streaks').select('longest_streak').eq('habit_id', habitId).maybeSingle();
    final previousLongest = (previousStreakRow?['longest_streak'] as int?) ?? 0;
    final longestOverall = [longest, previousLongest].reduce((a, b) => a > b ? a : b);

    await _client.from('habit_streaks').upsert({
      'habit_id': habitId,
      'current_streak': current,
      'longest_streak': longestOverall,
      'last_completed_date': _dateStr(mostRecent),
    });

    return (currentStreak: current, longestStreak: longestOverall);
  }

  @override
  Future<List<HabitLog>> getLogs({
    required String habitId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .gte('log_date', _dateStr(from))
        .lte('log_date', _dateStr(to))
        .order('log_date');
    return rows.map((r) => HabitLog.fromMap(r)).toList();
  }

  @override
  Future<double> getCompletionRate(String habitId, {int days = 30}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final logs = await getLogs(habitId: habitId, from: from, to: DateTime.now());
    if (logs.isEmpty) return 0;
    final completed = logs.where((l) => l.completed).length;
    return completed / days;
  }
}
