import 'achievement.dart';

abstract class AchievementRepository {
  /// All achievements in the catalog, flagged with unlock status for this user.
  Future<List<Achievement>> loadAllWithStatus();

  Future<UserLevel> loadUserLevel();

  /// Checks habit/streak/journal/etc. milestones and unlocks any newly
  /// earned achievements, awarding their XP. Call after significant
  /// actions (habit completion, streak update, goal completion...).
  Future<List<Achievement>> checkAndUnlockAchievements();
}
