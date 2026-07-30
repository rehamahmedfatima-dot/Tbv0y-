import 'onboarding_data.dart';

abstract class OnboardingRepository {
  /// Sends answers to Gemini and gets back 2-4 suggested identities,
  /// each with a small starter set of habits.
  Future<List<SuggestedIdentity>> analyzeWithAI(OnboardingData data);

  /// Persists profile answers, then creates the identities/habits/life
  /// areas the user confirmed from the AI suggestions. Marks
  /// onboarding_completed = true.
  Future<void> completeOnboarding({
    required OnboardingData data,
    required List<SuggestedIdentity> chosenIdentities,
  });
}
