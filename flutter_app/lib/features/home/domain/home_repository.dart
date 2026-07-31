import 'dashboard_data.dart';

abstract class HomeRepository {
  Future<DashboardData> loadDashboard();

  /// Computes today's discipline score from habits/mood/journal signals
  /// and upserts it into discipline_scores. Called once per app open.
  Future<int> calculateAndStoreTodayScore();

  /// Returns today's AI mission, generating and storing one via Gemini
  /// if it doesn't exist yet.
  Future<({String title, bool completed})> getOrGenerateTodayMission();

  Future<void> completeTodayMission();

  Future<void> logMood(String mood, int score);
}
