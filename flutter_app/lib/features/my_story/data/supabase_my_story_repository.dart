import 'dart:convert';
import '../../../core/ai/gemini_service.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/my_story_repository.dart';
import '../domain/story_report.dart';

class SupabaseMyStoryRepository implements MyStoryRepository {
  final _client = SupabaseService.client;
  final _ai = GeminiService.instance;
  String get _userId => SupabaseService.currentUser!.id;
  static const _title = 'The Story of Your Best Version';

  @override
  Future<StoryReport?> loadReport(int year) async {
    final row = await _client
        .from('story_reports')
        .select()
        .eq('user_id', _userId)
        .eq('report_year', year)
        .maybeSingle();
    if (row == null) return null;
    return StoryReport.fromContentJson(year, row['title'] as String? ?? _title, row['content'] as Map<String, dynamic>);
  }

  @override
  Future<StoryReport> generateReport(int year) async {
    final yearStart = '$year-01-01';
    final yearEnd = '$year-12-31';

    final habitsCompleted = await _client
        .from('habit_logs')
        .select('id')
        .eq('user_id', _userId)
        .eq('completed', true)
        .gte('log_date', yearStart)
        .lte('log_date', yearEnd);

    final longestStreakRow = await _client.from('habit_streaks').select('longest_streak');
    final longestStreak = (longestStreakRow as List)
        .fold<int>(0, (m, s) => (s['longest_streak'] as int? ?? 0) > m ? s['longest_streak'] as int : m);

    final booksCompleted = await _client
        .from('books')
        .select('title')
        .eq('user_id', _userId)
        .eq('status', 'completed');

    final goalsCompleted = await _client
        .from('goals')
        .select('title')
        .eq('user_id', _userId)
        .eq('status', 'completed')
        .gte('completed_at', yearStart)
        .lte('completed_at', yearEnd);

    final achievementsUnlocked = await _client
        .from('user_achievements')
        .select('achievements(title)')
        .eq('user_id', _userId)
        .gte('unlocked_at', yearStart)
        .lte('unlocked_at', yearEnd);

    final avgScoreRow = await _client
        .from('discipline_scores')
        .select('overall_score')
        .eq('user_id', _userId)
        .gte('score_date', yearStart)
        .lte('score_date', yearEnd);

    final scores = (avgScoreRow as List).map((r) => (r['overall_score'] as num).toDouble()).toList();
    final avgScore = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
    final firstHalfAvg = scores.length > 4
        ? scores.take(scores.length ~/ 2).reduce((a, b) => a + b) / (scores.length ~/ 2)
        : avgScore;
    final secondHalfAvg = scores.length > 4
        ? scores.skip(scores.length ~/ 2).reduce((a, b) => a + b) / (scores.length - scores.length ~/ 2)
        : avgScore;

    final prompt = '''
Write an uplifting, personal annual reflection called "The Story of Your
Best Version" for a user of TBVOY, a personal growth app. Use this real
data from their $year:

- Habits completed this year: ${(habitsCompleted as List).length}
- Longest streak achieved (all-time): $longestStreak days
- Books finished: ${(booksCompleted as List).map((b) => b['title']).join(', ').ifEmpty('none yet')}
- Goals completed: ${(goalsCompleted as List).map((g) => g['title']).join(', ').ifEmpty('none yet')}
- Achievements unlocked: ${(achievementsUnlocked as List).map((a) => a['achievements']?['title']).where((t) => t != null).join(', ').ifEmpty('none yet')}
- Average discipline score first half of year: ${firstHalfAvg.round()}, second half: ${secondHalfAvg.round()}

Respond with ONLY valid JSON in this exact shape:
{
  "opening_reflection": "1-2 warm sentences opening the story",
  "highlights": ["3-5 specific highlight strings drawn from the data"],
  "strengths": ["2-3 strength strings"],
  "suggested_improvements": ["1-2 gentle, encouraging suggestion strings"],
  "before_after": "1-2 sentences comparing early vs late year discipline/consistency",
  "closing_motivation": "1-2 motivating closing sentences"
}
''';

    Map<String, dynamic> content;
    try {
      final raw = await _ai.generateJson(prompt);
      content = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      content = {
        'opening_reflection': 'This year had its ups and downs — and you kept showing up.',
        'highlights': ['You completed ${(habitsCompleted).length} habit check-ins this year.'],
        'strengths': ['Consistency', 'Self-awareness'],
        'suggested_improvements': ['Try journaling a bit more regularly next year.'],
        'before_after': 'Your discipline held steady across the year.',
        'closing_motivation': 'Here\'s to becoming even more of your best version next year.',
      };
    }

    await _client.from('story_reports').upsert({
      'user_id': _userId,
      'report_year': year,
      'title': _title,
      'content': content,
      'generated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,report_year');

    return StoryReport.fromContentJson(year, _title, content);
  }
}

extension _EmptyFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
