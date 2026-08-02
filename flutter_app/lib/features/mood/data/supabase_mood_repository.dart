import 'dart:convert';
import '../../../core/ai/gemini_service.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/mood_entry.dart';
import '../domain/mood_repository.dart';

class SupabaseMoodRepository implements MoodRepository {
  final _client = SupabaseService.client;
  final _ai = GeminiService.instance;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<List<MoodLog>> loadHistory({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T').first;
    final rows = await _client
        .from('mood_logs')
        .select()
        .eq('user_id', _userId)
        .gte('log_date', since)
        .order('log_date');
    return (rows as List).map((r) => MoodLog.fromJson(r)).toList();
  }

  @override
  Future<void> logMood({
    required String mood,
    required int score,
    List<String> triggers = const [],
    String? note,
  }) async {
    await _client.from('mood_logs').insert({
      'user_id': _userId,
      'log_date': DateTime.now().toIso8601String().split('T').first,
      'mood': mood,
      'mood_score': score,
      'triggers': triggers,
      'note': note,
    });
  }

  @override
  Future<List<String>> suggestActivities() async {
    final history = await loadHistory(days: 7);
    final recentMood = history.isNotEmpty ? history.last.mood : 'neutral';

    final prompt = '''
The user's current mood is "$recentMood". Suggest 3 short, concrete,
realistic activities (under 6 words each) that could help sustain or
improve their mood right now. Respond with ONLY a JSON array of 3 strings,
no prose, e.g. ["Take a 10-minute walk", "Text a close friend", "Stretch for 5 minutes"]
''';

    try {
      final raw = await _ai.generateJson(prompt);
      final list = jsonDecode(raw);
      if (list is List) return list.cast<String>();
      return const ['Take a short walk', 'Drink some water', 'Write down one good thing'];
    } catch (_) {
      return const ['Take a short walk', 'Drink some water', 'Write down one good thing'];
    }
  }
}
