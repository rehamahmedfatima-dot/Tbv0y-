import 'focus_session.dart';

abstract class FocusRepository {
  Future<String> startSession(FocusSessionType type, int durationMinutes);
  Future<void> endSession(String sessionId, {required bool completed, required bool interrupted});

  Future<List<FocusSession>> loadRecentSessions({int days = 30});

  /// Total completed focus minutes today — used for stats + Discipline Score.
  Future<int> todayFocusMinutes();
}
