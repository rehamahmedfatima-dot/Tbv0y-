import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_home_repository.dart';
import '../../domain/dashboard_data.dart';
import '../../domain/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return SupabaseHomeRepository();
});

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() {
    return ref.watch(homeRepositoryProvider).loadDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(homeRepositoryProvider).loadDashboard());
  }

  Future<void> completeMission() async {
    final repo = ref.read(homeRepositoryProvider);
    final current = state.valueOrNull;
    if (current == null || current.missionCompleted) return;

    // Optimistic update.
    state = AsyncData(DashboardData(
      disciplineScore: current.disciplineScore,
      weeklyDisciplineTrend: current.weeklyDisciplineTrend,
      todaysMood: current.todaysMood,
      todaysQuote: current.todaysQuote,
      todaysMissionTitle: current.todaysMissionTitle,
      missionCompleted: true,
      longestActiveStreak: current.longestActiveStreak,
      todayHabitCompletionRate: current.todayHabitCompletionRate,
      treeStage: current.treeStage,
      treeHealth: current.treeHealth,
      treeSeason: current.treeSeason,
      xp: current.xp,
      level: current.level,
      motivationalMessage: current.motivationalMessage,
    ));

    try {
      await repo.completeTodayMission();
    } catch (_) {
      state = AsyncData(current); // roll back
    }
  }

  Future<void> logMood(String mood, int score) async {
    await ref.read(homeRepositoryProvider).logMood(mood, score);
    await refresh();
  }
}

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardData>(DashboardNotifier.new);
