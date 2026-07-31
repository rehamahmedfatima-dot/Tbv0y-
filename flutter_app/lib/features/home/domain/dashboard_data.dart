class DashboardData {
  final int disciplineScore; // 0-100, today
  final List<int> weeklyDisciplineTrend; // last 7 days, oldest first
  final String? todaysMood; // great|good|neutral|low|bad, null if not logged yet
  final String todaysQuote;
  final String todaysMissionTitle;
  final bool missionCompleted;
  final int longestActiveStreak;
  final double todayHabitCompletionRate; // 0-1
  final int treeStage;
  final double treeHealth;
  final String treeSeason;
  final int xp;
  final int level;
  final String motivationalMessage;

  const DashboardData({
    required this.disciplineScore,
    required this.weeklyDisciplineTrend,
    required this.todaysMood,
    required this.todaysQuote,
    required this.todaysMissionTitle,
    required this.missionCompleted,
    required this.longestActiveStreak,
    required this.todayHabitCompletionRate,
    required this.treeStage,
    required this.treeHealth,
    required this.treeSeason,
    required this.xp,
    required this.level,
    required this.motivationalMessage,
  });
}
