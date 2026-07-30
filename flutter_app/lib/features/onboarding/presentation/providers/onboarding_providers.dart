import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_onboarding_repository.dart';
import '../../domain/onboarding_data.dart';
import '../../domain/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return SupabaseOnboardingRepository();
});

/// Holds the in-progress answers as the user moves through the 5 pages.
class OnboardingDraftNotifier extends StateNotifier<OnboardingData> {
  OnboardingDraftNotifier() : super(const OnboardingData());

  void updateBasicInfo({String? name, int? age, String? gender, String? occupation, String? language}) {
    state = state.copyWith(
      name: name,
      age: age,
      gender: gender,
      occupation: occupation,
      preferredLanguage: language,
    );
  }

  void updateSchedule({String? wakeUpTime, String? sleepTime}) {
    state = state.copyWith(wakeUpTime: wakeUpTime, sleepTime: sleepTime);
  }

  void updateHabits({List<String>? currentHabits, List<String>? badHabits}) {
    state = state.copyWith(currentHabits: currentHabits, badHabits: badHabits);
  }

  void updatePrioritiesAndDreams({
    Map<String, int>? lifePriorities,
    List<String>? bigDreams,
    String? goalsFreeText,
    List<String>? desiredIdentities,
  }) {
    state = state.copyWith(
      lifePriorities: lifePriorities,
      bigDreams: bigDreams,
      goalsFreeText: goalsFreeText,
      desiredIdentities: desiredIdentities,
    );
  }

  void updateNotificationTimes(List<String> times) {
    state = state.copyWith(notificationTimes: times);
  }
}

final onboardingDraftProvider =
    StateNotifierProvider<OnboardingDraftNotifier, OnboardingData>((ref) {
  return OnboardingDraftNotifier();
});

enum OnboardingStatus { idle, analyzing, saving, error, done }

class OnboardingController extends StateNotifier<OnboardingStatus> {
  OnboardingController(this._repo) : super(OnboardingStatus.idle);
  final OnboardingRepository _repo;

  List<SuggestedIdentity> suggestions = [];
  String? errorMessage;

  Future<bool> analyze(OnboardingData data) async {
    state = OnboardingStatus.analyzing;
    errorMessage = null;
    try {
      suggestions = await _repo.analyzeWithAI(data);
      state = OnboardingStatus.idle;
      return true;
    } catch (e) {
      errorMessage = 'Could not analyze your answers. Please try again.';
      state = OnboardingStatus.error;
      return false;
    }
  }

  Future<bool> complete(OnboardingData data, List<SuggestedIdentity> chosen) async {
    state = OnboardingStatus.saving;
    errorMessage = null;
    try {
      await _repo.completeOnboarding(data: data, chosenIdentities: chosen);
      state = OnboardingStatus.done;
      return true;
    } catch (e) {
      errorMessage = 'Could not save your profile. Please try again.';
      state = OnboardingStatus.error;
      return false;
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingStatus>((ref) {
  return OnboardingController(ref.watch(onboardingRepositoryProvider));
});
