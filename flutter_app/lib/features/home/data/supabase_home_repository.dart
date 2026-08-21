import '../../../core/ai/gemini_service.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/dashboard_data.dart';
import '../domain/home_repository.dart';

const _quotes = [
  'Small steps, repeated daily, become a completely different life.',
  'Discipline is choosing between what you want now and what you want most.',
  'You do not rise to the level of your goals, you fall to the level of your systems.',
  'The best version of you is built one small action at a time.',
  'Consistency turns ordinary days into an extraordinary life.',
];

class SupabaseHomeRepository implements HomeRepository {
  final _client = SupabaseService.client;
  final _ai = GeminiService.instance;

  String get _userId {
    final id = SupabaseService.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  String _today() => DateTime.now().toIso8601String().split('T').first;
  String _dateStr(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<DashboardData> loadDashboard() async {
    final scoreFuture = calculateAndStoreTodayScore();
    final missionFuture = getOrGenerateTodayMission();

    final moodFuture = _client
        .from('mood_logs')
        .select('mood')
        .eq('user_id', _userId)
        .eq('log_date', _today())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final streakFuture = _client
        .from('habit_streaks')
        .select('current_streak, habits!inner(user_id)')
        .eq('habits.user_id', _userId)
        .order('current_streak', ascending: false)
        .limit(1);

    final habitsFuture = _client
        .from('habits')
        .select('id')
        .eq('user_id', _userId)
        .eq('is_active', true);

    final treeFuture = _client
        .from('growth_tree_state')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    final levelFuture = _client
        .from('user_levels')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    final moodRow = await moodFuture;
    final streakRows = await streakFuture;
    final habits = await habitsFuture;
    final tree = await treeFuture;
    final level = await levelFuture;

    final score = await scoreFuture;
    final mission = await missionFuture;

    final weeklyRows = await _client
        .from('discipline_scores')
        .select('score_date, overall_score')
        .eq('user_id', _userId)
        .gte(
          'score_date',
          _dateStr(
            DateTime.now().subtract(
              const Duration(days: 6),
            ),
          ),
        )
        .order('score_date');

    final Map<String, int> scoresByDate = {};

    for (final row in weeklyRows) {
      scoresByDate[row['score_date'] as String] =
          (row['overall_score'] as num).round();
    }

    final List<int> weeklyTrend = [];

    for (int i = 6; i >= 0; i--) {
      final date = _dateStr(
        DateTime.now().subtract(
          Duration(days: i),
        ),
      );

      weeklyTrend.add(scoresByDate[date] ?? 0);
    }

    final longestActive = streakRows.isEmpty
        ? 0
        : (streakRows.first['current_streak'] as int? ?? 0);

    double completionRate = 0;

    if (habits.isNotEmpty) {
      final habitIds =
          habits.map((h) => h['id'] as String).toList();

      final todayLogs = await _client
          .from('habit_logs')
          .select('completed')
          .inFilter('habit_id', habitIds)
          .eq('log_date', _today())
          .eq('completed', true);

      completionRate =
          todayLogs.length / habits.length;
    }

    final motivational =
        await _generateMotivationalMessage(
      score: score,
      completionRate: completionRate,
      streak: longestActive,
    );

    return DashboardData(
      disciplineScore: score,
      weeklyDisciplineTrend: weeklyTrend,
      todaysMood: moodRow?['mood'] as String?,
      todaysQuote:
          _quotes[DateTime.now().day % _quotes.length],
      todaysMissionTitle: mission.title,
      missionCompleted: mission.completed,
      longestActiveStreak: longestActive,
      todayHabitCompletionRate: completionRate,
      treeStage:
          tree?['tree_stage'] as int? ?? 1,
      treeHealth:
          (tree?['health'] as num?)?.toDouble() ?? 100,
      treeSeason:
          tree?['season'] as String? ?? 'spring',
      xp: level?['xp'] as int? ?? 0,
      level: level?['level'] as int? ?? 1,
      motivationalMessage: motivational,
    );
  }

  @override
  Future<int> calculateAndStoreTodayScore() async {
    final habits = await _client.from('habits').select('id').eq('user_id', _userId).eq('is_active', true);

    double habitScore = 50; // neutral default when there's nothing to measure yet
    if (habits.isNotEmpty) {
      final habitIds = habits.map((h) => h['id'] as String).toList();
      final completed = await _client
          .from('habit_logs')
          .select('completed')
          .inFilter('habit_id', habitIds)
          .eq('log_date', _today())
          .eq('completed', true);
      habitScore = (completed.length / habits.length) * 100;
    }

    final journalToday = await _client
        .from('journal_entries')
        .select('id')
        .eq('user_id', _userId)
        .eq('entry_date', _today())
        .limit(1);
    final journalScore = journalToday.isNotEmpty ? 100.0 : 0.0;

    final moodToday = await _client
        .from('mood_logs')
        .select('mood_score')
        .eq('user_id', _userId)
        .eq('log_date', _today())
        .limit(1)
        .maybeSingle();
    final moodScore = moodToday != null ? ((moodToday['mood_score'] as int? ?? 5) / 10) * 100 : 50.0;

    final focusToday = await _client
        .from('focus_sessions')
        .select('id')
        .eq('user_id', _userId)
        .gte('started_at', '${_today()}T00:00:00')
        .eq('completed', true)
        .limit(1);
    final focusScore = focusToday.isNotEmpty ? 100.0 : 0.0;

    // Weighted composite â€” habits matter most since they're the daily
    // driver; the rest are supporting signals.
    final overall = (habitScore * 0.5) + (journalScore * 0.15) + (moodScore * 0.15) + (focusScore * 0.2);
    final rounded = overall.round().clamp(0, 100);

    await _client.from('discipline_scores').upsert({
      'user_id': _userId,
      'score_date': _today(),
      'overall_score': rounded,
      'habit_completion_score': habitScore.round(),
      'journal_score': journalScore.round(),
      'mood_score': moodScore.round(),
      'focus_score': focusScore.round(),
    }, onConflict: 'user_id,score_date');

    return rounded;
  }

  @override
  Future<({String title, bool completed})> getOrGenerateTodayMission() async {
    final existing = await _client
        .from('ai_missions')
        .select()
        .eq('user_id', _userId)
        .eq('mission_date', _today())
        .maybeSingle();

    if (existing != null) {
      return (title: existing['title'] as String, completed: existing['is_completed'] as bool? ?? false);
    }

    final identities = await _client.from('identities').select('title').eq('user_id', _userId).limit(3);
    final identityTitles = identities.map((i) => i['title'] as String).join(', ');

    final prompt = '''
Generate ONE small, specific, achievable mission for today for someone
working on becoming: ${identityTitles.isEmpty ? 'their best self' : identityTitles}.
It must be doable in under 20 minutes. Respond with ONLY the mission text,
under 10 words, no quotes, no punctuation at the end. Example: "Read 10 pages of a book"
''';

    String title;
    try {
      title = await _ai.generateText(prompt);
      if (title.isEmpty || title.length > 80) title = 'Take a 10-minute mindful walk';
    } catch (_) {
      title = 'Take a 10-minute mindful walk';
    }

    await _client.from('ai_missions').insert({
      'user_id': _userId,
      'mission_date': _today(),
      'title': title,
    });

    return (title: title, completed: false);
  }

  @override
  Future<void> completeTodayMission() async {
    await _client
        .from('ai_missions')
        .update({'is_completed': true, 'completed_at': DateTime.now().toIso8601String()})
        .eq('user_id', _userId)
        .eq('mission_date', _today());

    await _addXp(15);
  }

  @override
  Future<void> logMood(String mood, int score) async {
    await _client.from('mood_logs').insert({
      'user_id': _userId,
      'log_date': _today(),
      'mood': mood,
      'mood_score': score,
    });
  }

  Future<void> _addXp(int amount) async {
    final current = await _client.from('user_levels').select().eq('user_id', _userId).maybeSingle();
    final xp = (current?['xp'] as int? ?? 0) + amount;
    final level = (xp ~/ 100) + 1; // simple curve: 100xp per level
    await _client.from('user_levels').upsert({'user_id': _userId, 'xp': xp, 'level': level});
  }

  Future<String> _generateMotivationalMessage({
    required int score,
    required double completionRate,
    required int streak,
  }) async {
    final prompt = '''
Write ONE short, warm, encouraging sentence (under 20 words) for a personal
growth app's home screen. Today's discipline score is $score/100, habit
completion is ${(completionRate * 100).round()}%, current streak is $streak days.
Be specific to these numbers, not generic. No quotes, no emoji.
''';
    try {
      final msg = await _ai.generateText(prompt);
      return msg.isEmpty ? 'Every small action today is building the person you\'re becoming.' : msg;
    } catch (_) {
      return 'Every small action today is building the person you\'re becoming.';
    }
  }
}
