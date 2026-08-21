@override
Future<DashboardData> loadDashboard() async {
  // Keep the initial dashboard load fast and independent.
  // Each independent Supabase request can run in parallel instead
  // of waiting for the previous request to finish.

  final scoreFuture = calculateAndStoreTodayScore();
  final missionFuture = getOrGenerateTodayMission();

  final weeklyRowsFuture = _client
      .from('discipline_scores')
      .select('score_date, overall_score')
      .eq('user_id', _userId)
      .gte(
        'score_date',
        _dateStr(
          DateTime.now().subtract(const Duration(days: 6)),
        ),
      )
      .order('score_date');

  final moodRowFuture = _client
      .from('mood_logs')
      .select('mood')
      .eq('user_id', _userId)
      .eq('log_date', _today())
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  final streakRowsFuture = _client
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

  // Wait for the independent requests together.
  final score = await scoreFuture;
  final mission = await missionFuture;

  final weeklyRows = await weeklyRowsFuture;
  final moodRow = await moodRowFuture;
  final streakRows = await streakRowsFuture;
  final habits = await habitsFuture;
  final tree = await treeFuture;
  final level = await levelFuture;

  final scoresByDate = {
    for (final r in weeklyRows)
      r['score_date'] as String:
          (r['overall_score'] as num).round(),
  };

  final weeklyTrend = [
    for (int i = 6; i >= 0; i--)
      scoresByDate[
            _dateStr(
              DateTime.now().subtract(Duration(days: i)),
            ),
          ] ??
          0,
  ];

  final longestActive =
      streakRows.isEmpty
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

    completionRate = todayLogs.length / habits.length;
  }

  final motivational = await _generateMotivationalMessage(
    score: score,
    completionRate: completionRate,
    streak: longestActive,
  );

  return DashboardData(
    disciplineScore: score,
    weeklyDisciplineTrend: weeklyTrend,
    todaysMood: moodRow?['mood'] as String?,
    todaysQuote: _quotes[DateTime.now().day % _quotes.length],
    todaysMissionTitle: mission.title,
    missionCompleted: mission.completed,
    longestActiveStreak: longestActive,
    todayHabitCompletionRate: completionRate,
    treeStage: tree?['tree_stage'] as int? ?? 1,
    treeHealth: (tree?['health'] as num?)?.toDouble() ?? 100,
    treeSeason: tree?['season'] as String? ?? 'spring',
    xp: level?['xp'] as int? ?? 0,
    level: level?['level'] as int? ?? 1,
    motivationalMessage: motivational,
  );
}
