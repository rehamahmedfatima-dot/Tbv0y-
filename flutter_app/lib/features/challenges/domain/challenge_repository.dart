import 'challenge.dart';

abstract class ChallengeRepository {
  /// Global + the user's own custom challenges, annotated with their
  /// participation status.
  Future<List<Challenge>> loadChallenges();

  Future<void> createCustomChallenge({required String title, String? description, required int durationDays});

  Future<void> joinChallenge(String challengeId);
  Future<void> markTodayDone(String challengeId);
  Future<void> abandonChallenge(String challengeId);
}
