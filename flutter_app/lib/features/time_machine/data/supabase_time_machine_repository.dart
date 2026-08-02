import '../../../core/network/supabase_service.dart';
import '../domain/day_replay.dart';
import '../domain/time_machine_repository.dart';

class SupabaseTimeMachineRepository implements TimeMachineRepository {
  final _client = SupabaseService.client;
  String get _userId => SupabaseService.currentUser!.id;

  String _fmt(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<DayReplay> loadDay(DateTime date) async {
    final dateStr = _fmt(date);

    final scoreRow = await _client
        .from('discipline_scores')
        .select('overall_score')
        .eq('user_id', _userId)
        .eq('score_date', dateStr)
        .maybeSingle();

    final moodRow = await _client
        .from('mood_logs')
        .select('mood')
        .eq('user_id', _userId)
        .eq('log_date', dateStr)
        .maybeSingle();

    final habitLogs = await _client
        .from('habit_logs')
        .select('completed, habits(title)')
        .eq('user_id', _userId)
        .eq('log_date', dateStr);

    final journalRows = await _client
        .from('journal_entries')
        .select('entry_type, content')
        .eq('user_id', _userId)
        .eq('entry_date', dateStr);

    return DayReplay(
      date: date,
      disciplineScore: scoreRow != null ? (scoreRow['overall_score'] as num).round() : null,
      mood: moodRow?['mood'] as String?,
      habits: (habitLogs as List)
          .map((h) => (title: h['habits']?['title'] as String? ?? 'Habit', completed: h['completed'] as bool))
          .toList(),
      journalEntries: (journalRows as List)
          .map((j) => (type: j['entry_type'] as String, content: j['content'] as String? ?? ''))
          .toList(),
    );
  }

  @override
  Future<Set<String>> loadActiveDates({required DateTime from, required DateTime to}) async {
    final fromStr = _fmt(from);
    final toStr = _fmt(to);

    final scores = await _client
        .from('discipline_scores')
        .select('score_date')
        .eq('user_id', _userId)
        .gte('score_date', fromStr)
        .lte('score_date', toStr);

    return (scores as List).map((s) => s['score_date'] as String).toSet();
  }
}
