import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_goal_repository.dart';
import '../../domain/goal.dart';
import '../../domain/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) => SupabaseGoalRepository());

class GoalsNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  GoalsNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }
  final GoalRepository _repo;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.loadGoals());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(String title, String? description, GoalType type, DateTime? targetDate) async {
    await _repo.createGoal(title: title, description: description, type: type, targetDate: targetDate);
    await refresh();
  }

  Future<void> toggleMilestone(String milestoneId, bool completed) async {
    await _repo.toggleMilestone(milestoneId, completed);
    await refresh();
  }

  Future<void> generateRoadmap(String goalId) async {
    await _repo.generateRoadmap(goalId);
    await refresh();
  }

  Future<void> markCompleted(String goalId) async {
    await _repo.markCompleted(goalId);
    await refresh();
  }

  Future<void> delete(String goalId) async {
    await _repo.deleteGoal(goalId);
    await refresh();
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, AsyncValue<List<Goal>>>(
  (ref) => GoalsNotifier(ref.watch(goalRepositoryProvider)),
);

final suggestedGoalsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(goalRepositoryProvider).suggestNextGoals();
});
