import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_mood_repository.dart';
import '../../domain/mood_entry.dart';
import '../../domain/mood_repository.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) => SupabaseMoodRepository());

class MoodHistoryNotifier extends StateNotifier<AsyncValue<List<MoodLog>>> {
  MoodHistoryNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }
  final MoodRepository _repo;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.loadHistory());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> log(String mood, int score) async {
    await _repo.logMood(mood: mood, score: score);
    await refresh();
  }
}

final moodHistoryProvider = StateNotifierProvider<MoodHistoryNotifier, AsyncValue<List<MoodLog>>>(
  (ref) => MoodHistoryNotifier(ref.watch(moodRepositoryProvider)),
);

final suggestedActivitiesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(moodRepositoryProvider).suggestActivities();
});
