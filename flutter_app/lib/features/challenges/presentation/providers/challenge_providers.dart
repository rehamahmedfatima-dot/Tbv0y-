import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_challenge_repository.dart';
import '../../domain/challenge.dart';
import '../../domain/challenge_repository.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) => SupabaseChallengeRepository());

class ChallengesNotifier extends StateNotifier<AsyncValue<List<Challenge>>> {
  ChallengesNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }
  final ChallengeRepository _repo;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.loadChallenges());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> join(String id) async {
    await _repo.joinChallenge(id);
    await refresh();
  }

  Future<void> markTodayDone(String id) async {
    await _repo.markTodayDone(id);
    await refresh();
  }

  Future<void> abandon(String id) async {
    await _repo.abandonChallenge(id);
    await refresh();
  }

  Future<void> createCustom(String title, String? description, int days) async {
    await _repo.createCustomChallenge(title: title, description: description, durationDays: days);
    await refresh();
  }
}

final challengesProvider = StateNotifierProvider<ChallengesNotifier, AsyncValue<List<Challenge>>>(
  (ref) => ChallengesNotifier(ref.watch(challengeRepositoryProvider)),
);
