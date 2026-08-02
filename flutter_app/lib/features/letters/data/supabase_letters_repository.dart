import '../../../core/ai/gemini_service.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/letter.dart';

abstract class LettersRepository {
  Future<List<Letter>> loadLetters();
  Future<void> writeLetter({required String content, required DateTime openAt, String? title});
  Future<void> markOpened(String letterId);
  Future<String> generateAiLetter();
}

class SupabaseLettersRepository implements LettersRepository {
  final _client = SupabaseService.client;
  final _ai = GeminiService.instance;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<List<Letter>> loadLetters() async {
    final rows = await _client
        .from('letters')
        .select()
        .eq('user_id', _userId)
        .order('open_at');
    return (rows as List).map((r) => Letter.fromJson(r)).toList();
  }

  @override
  Future<void> writeLetter({required String content, required DateTime openAt, String? title}) async {
    await _client.from('letters').insert({
      'user_id': _userId,
      'author': 'user',
      'title': title,
      'content': content,
      'open_at': openAt.toIso8601String(),
    });
  }

  @override
  Future<void> markOpened(String letterId) async {
    await _client.from('letters').update({
      'opened': true,
      'opened_at': DateTime.now().toIso8601String(),
    }).eq('id', letterId);
  }

  @override
  Future<String> generateAiLetter() async {
    final score = await _client
        .from('discipline_scores')
        .select('overall_score')
        .eq('user_id', _userId)
        .order('score_date', ascending: false)
        .limit(7);

    final avg = (score as List).isEmpty
        ? null
        : score.map((s) => s['overall_score'] as num).reduce((a, b) => a + b) / score.length;

    final content = await _ai.generateText(
      'Write a warm, motivational letter from the user\'s future self, one '
      'year from now, addressed to their present self. ${avg != null ? "Their recent discipline score has averaged ${avg.toStringAsFixed(0)}/100." : ""} '
      'Keep it under 150 words, second person, hopeful and specific, no cliches like "dear past me".',
    );

    final openAt = DateTime.now().add(const Duration(days: 365));
    await _client.from('letters').insert({
      'user_id': _userId,
      'author': 'ai',
      'title': 'From your future self',
      'content': content,
      'open_at': openAt.toIso8601String(),
    });

    return content;
  }
}
