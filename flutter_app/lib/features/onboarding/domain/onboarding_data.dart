/// Everything collected during onboarding. Immutable — each page produces
/// a new copy via copyWith as the user answers.
class OnboardingData {
  final String? name;
  final int? age;
  final String? gender; // 'male' | 'female' | 'other' | 'prefer_not_to_say'
  final String? occupation;
  final String? preferredLanguage; // 'en' | 'ar' | ...

  final String? wakeUpTime; // 'HH:mm'
  final String? sleepTime; // 'HH:mm'

  final List<String> currentHabits;
  final List<String> badHabits;

  final Map<String, int> lifePriorities; // area_key -> importance 1-10
  final List<String> bigDreams;
  final String? goalsFreeText;

  final List<String> desiredIdentities; // e.g. "Athlete", "Reader"

  final List<String> notificationTimes; // 'HH:mm' list

  const OnboardingData({
    this.name,
    this.age,
    this.gender,
    this.occupation,
    this.preferredLanguage = 'en',
    this.wakeUpTime,
    this.sleepTime,
    this.currentHabits = const [],
    this.badHabits = const [],
    this.lifePriorities = const {},
    this.bigDreams = const [],
    this.goalsFreeText,
    this.desiredIdentities = const [],
    this.notificationTimes = const [],
  });

  OnboardingData copyWith({
    String? name,
    int? age,
    String? gender,
    String? occupation,
    String? preferredLanguage,
    String? wakeUpTime,
    String? sleepTime,
    List<String>? currentHabits,
    List<String>? badHabits,
    Map<String, int>? lifePriorities,
    List<String>? bigDreams,
    String? goalsFreeText,
    List<String>? desiredIdentities,
    List<String>? notificationTimes,
  }) {
    return OnboardingData(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      sleepTime: sleepTime ?? this.sleepTime,
      currentHabits: currentHabits ?? this.currentHabits,
      badHabits: badHabits ?? this.badHabits,
      lifePriorities: lifePriorities ?? this.lifePriorities,
      bigDreams: bigDreams ?? this.bigDreams,
      goalsFreeText: goalsFreeText ?? this.goalsFreeText,
      desiredIdentities: desiredIdentities ?? this.desiredIdentities,
      notificationTimes: notificationTimes ?? this.notificationTimes,
    );
  }

  /// True once every required field (not just nice-to-haves) is filled.
  bool get isComplete =>
      name != null &&
      name!.trim().isNotEmpty &&
      age != null &&
      gender != null &&
      wakeUpTime != null &&
      sleepTime != null &&
      desiredIdentities.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'occupation': occupation,
        'preferred_language': preferredLanguage,
        'wake_up_time': wakeUpTime,
        'sleep_time': sleepTime,
        'current_habits': currentHabits,
        'bad_habits': badHabits,
        'life_priorities': lifePriorities,
        'big_dreams': bigDreams,
        'goals': goalsFreeText,
        'desired_identities': desiredIdentities,
        'notification_times': notificationTimes,
      };
}

/// One AI-suggested identity with the starter habits that support it —
/// returned by GeminiService after analyzing onboarding answers.
class SuggestedIdentity {
  final String title;
  final String description;
  final String icon;
  final List<SuggestedHabit> habits;

  const SuggestedIdentity({
    required this.title,
    required this.description,
    required this.icon,
    required this.habits,
  });

  factory SuggestedIdentity.fromJson(Map<String, dynamic> json) {
    return SuggestedIdentity(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'star',
      habits: (json['habits'] as List<dynamic>? ?? [])
          .map((h) => SuggestedHabit.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SuggestedHabit {
  final String title;
  final String category; // maps to habit_categories.key
  final String frequencyType; // 'daily' | 'weekly' | 'x_times_per_week'
  final int? timesPerWeek;

  const SuggestedHabit({
    required this.title,
    required this.category,
    required this.frequencyType,
    this.timesPerWeek,
  });

  factory SuggestedHabit.fromJson(Map<String, dynamic> json) {
    return SuggestedHabit(
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'custom',
      frequencyType: json['frequency_type'] as String? ?? 'daily',
      timesPerWeek: json['times_per_week'] as int?,
    );
  }
}
