import 'goal.dart';

abstract class GoalRepository {
  Future<List<Goal>> loadGoals();

  Future<Goal> createGoal({
    required String title,
    String? description,
    required GoalType type,
    DateTime? targetDate,
  });

  Future<void> updateProgress(String goalId, double progressPercent);
  Future<void> markCompleted(String goalId);
  Future<void> deleteGoal(String goalId);

  Future<void> toggleMilestone(String milestoneId, bool completed);

  /// Gemini breaks the goal into a concrete milestone roadmap and stores it.
  Future<List<String>> generateRoadmap(String goalId);

  /// AI-suggested next goals based on identities, life areas, and history.
  Future<List<String>> suggestNextGoals();
}
