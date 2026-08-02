import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_achievement_repository.dart';
import '../../domain/achievement.dart';
import '../../domain/achievement_repository.dart';

final achievementRepositoryProvider =
    Provider<AchievementRepository>((ref) => SupabaseAchievementRepository());

final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((ref) async {
  final repo = ref.watch(achievementRepositoryProvider);
  // Check for newly-earned achievements every time this is watched (app
  // open, My Journey, or the Achievements screen) — cheap enough to run
  // on each load and keeps unlocks from being silently missed.
  await repo.checkAndUnlockAchievements();
  return repo.loadAllWithStatus();
});

final userLevelProvider = FutureProvider.autoDispose<UserLevel>((ref) {
  return ref.watch(achievementRepositoryProvider).loadUserLevel();
});
