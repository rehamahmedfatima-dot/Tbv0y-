import '../../../core/network/supabase_service.dart';
import '../domain/achievement.dart';
import '../domain/achievement_repository.dart';

class SupabaseAchievementRepository implements AchievementRepository {
  final _client = SupabaseService.client;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<List<Achievement>> loadAllWithStatus() async {
    final all = await _client.from('achievements').select();
    final unlocked = await _client
        .from('user_achievements')
        .select('achievement_id, unlocked_at')
        .eq('user_id', _userId);

    final unlockedMap = {
      for (final u in (unlocked as List)) u['achievement_id'] as String: u['unlocked_at'] as String,
    };

    return (all as List).map((a) {
      final id = a['id'] as String;
      final unlockedAtStr = unlockedMap[id];
      return Achievement.fromJson(
        a,
        unlocked: unlockedAtStr != null,
        unlockedAt: unlockedAtStr != null ? DateTime.parse(unlockedAtStr) : null,
      );
    }).toList();
  }

  @override
  Future<UserLevel> loadUserLevel() async {
    final row = await _client.from('user_levels').select().eq('user_id', _userId).maybeSingle();
    return row != null ? UserLevel.fromJson(row) : const UserLevel(xp: 0, level: 1);
  }

  Future<void> _unlock(String achievementKey, int xpReward) async {
    final achievement =
        await _client.from('achievements').select('id').eq('key', achievementKey).maybeSingle();
    if (achievement == null) return;

    final achievementId = achievement['id'] as String;
    final alreadyUnlocked = await _client
        .from('user_achievements')
        .select('id')
        .eq('user_id', _userId)
        .eq('achievement_id', achievementId)
        .maybeSingle();
    if (alreadyUnlocked != null) return;

    await _client.from('user_achievements').insert({'user_id': _userId, 'achievement_id': achievementId});

    final level = await loadUserLevel();
    final newXp = level.xp + xpReward;
    final newLevel = (1 + (newXp / 130).floor()).clamp(1, 999);
    await _client.from('user_levels').upsert({'user_id': _userId, 'xp': newXp, 'level': newLevel});
  }

  @override
  Future<List<Achievement>> checkAndUnlockAchievements() async {
    final before = await loadAllWithStatus();
    final unlockedBefore = before.where((a) => a.unlocked).map((a) => a.key).toSet();

    // Streak milestones
    final streaks = await _client.from('habit_streaks').select('current_streak, longest_streak');
    final maxStreak = (streaks as List).fold<int>(
        0, (m, s) => (s['longest_streak'] as int? ?? 0) > m ? (s['longest_streak'] as int) : m);
    if (maxStreak >= 7) await _unlock('streak_7', 50);
    if (maxStreak >= 30) await _unlock('streak_30', 200);
    if (maxStreak >= 100) await _unlock('streak_100', 500);

    // First habit completed
    final firstLog = await _client
        .from('habit_logs')
        .select('id')
        .eq('user_id', _userId)
        .eq('completed', true)
        .limit(1);
    if ((firstLog as List).isNotEmpty) await _unlock('first_habit', 20);

    // Journal milestones
    final journalCount = await _client.from('journal_entries').select('id').eq('user_id', _userId);
    if ((journalCount as List).length >= 1) await _unlock('first_journal', 20);
    if (journalCount.length >= 30) await _unlock('journal_30', 150);

    // Goals completed
    final goalsCompleted =
        await _client.from('goals').select('id').eq('user_id', _userId).eq('status', 'completed');
    if ((goalsCompleted as List).isNotEmpty) await _unlock('first_goal', 50);

    // Books completed
    final booksCompleted =
        await _client.from('books').select('id').eq('user_id', _userId).eq('status', 'completed');
    if ((booksCompleted as List).isNotEmpty) await _unlock('first_book', 30);

    final after = await loadAllWithStatus();
    return after.where((a) => a.unlocked && !unlockedBefore.contains(a.key)).toList();
  }
}
