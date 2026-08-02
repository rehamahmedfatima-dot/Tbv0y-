import '../../../core/network/supabase_service.dart';
import '../domain/focus_session.dart';
import '../domain/focus_repository.dart';

class SupabaseFocusRepository implements FocusRepository {
  final _client = SupabaseService.client;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<String> startSession(FocusSessionType type, int durationMinutes) async {
    final row = await _client
        .from('focus_sessions')
        .insert({
          'user_id': _userId,
          'session_type': focusTypeToString(type),
          'duration_minutes': durationMinutes,
          'started_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<void> endSession(String sessionId, {required bool completed, required bool interrupted}) async {
    await _client.from('focus_sessions').update({
      'completed': completed,
      'interrupted': interrupted,
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);
  }

  @override
  Future<List<FocusSession>> loadRecentSessions({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await _client
        .from('focus_sessions')
        .select()
        .eq('user_id', _userId)
        .gte('started_at', since)
        .order('started_at', ascending: false);
    return (rows as List).map((r) => FocusSession.fromJson(r)).toList();
  }

  @override
  Future<int> todayFocusMinutes() async {
    final todayStart = DateTime.now();
    final start = DateTime(todayStart.year, todayStart.month, todayStart.day).toIso8601String();

    final rows = await _client
        .from('focus_sessions')
        .select('duration_minutes')
        .eq('user_id', _userId)
        .eq('completed', true)
        .gte('started_at', start);

    return (rows as List).fold<int>(0, (sum, r) => sum + (r['duration_minutes'] as int));
  }
}
