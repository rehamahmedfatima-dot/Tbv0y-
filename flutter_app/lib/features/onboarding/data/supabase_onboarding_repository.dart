import 'dart:convert';

import '../../../core/ai/gemini_service.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/onboarding_data.dart';
import '../domain/onboarding_repository.dart';

class SupabaseOnboardingRepository implements OnboardingRepository {
  final _client = SupabaseService.client;
  final _ai = GeminiService.instance;

  @override
  Future<List<SuggestedIdentity>> analyzeWithAI(
    OnboardingData data,
  ) async {
    final prompt = '''
You are the onboarding analyst for TBVOY, a personal growth app. Based on the
user's answers below, suggest 3 identities they could become ("Who do you
want to become" — not vague goals, concrete identities like "Disciplined
Athlete" or "Consistent Reader"), each with 2-3 small, realistic starter
habits.

User answers:
- Current habits: ${data.currentHabits.join(', ')}
- Bad habits they want to change: ${data.badHabits.join(', ')}
- Life priorities (area -> importance out of 10): ${jsonEncode(data.lifePriorities)}
- Big dreams: ${data.bigDreams.join(', ')}
- Goals: ${data.goalsFreeText ?? 'not specified'}
- Identities they already said they want: ${data.desiredIdentities.join(', ')}
- Wake up: ${data.wakeUpTime}, Sleep: ${data.sleepTime}

Respond with ONLY valid JSON matching this exact shape, no prose:
{
  "identities": [
    {
      "title": "string",
      "description": "one motivating sentence",
      "icon": "one of: star, book, dumbbell, briefcase, heart, brain, moon, leaf, trending-up",
      "habits": [
        {
          "title": "string",
          "category": "one of: health, fitness, reading, learning, work, prayer, meditation, finance, relationships, custom",
          "frequency_type": "one of: daily, weekly, x_times_per_week",
          "times_per_week": 3
        }
      ]
    }
  ]
}
''';

    try {
      final raw = await _ai.generateJson(prompt);

      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final list = parsed['identities'] as List<dynamic>? ?? [];

      final identities = list
          .map(
            (e) => SuggestedIdentity.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();

      if (identities.isEmpty) {
        return _defaultIdentity();
      }

      return identities;
    } catch (e) {
      return _defaultIdentity();
    }
  }

  List<SuggestedIdentity> _defaultIdentity() {
    return const [
      SuggestedIdentity(
        title: 'Consistent Beginner',
        description: 'Start small, show up daily, build momentum.',
        icon: 'trending-up',
        habits: [
          SuggestedHabit(
            title: 'Write one journal line',
            category: 'custom',
            frequencyType: 'daily',
          ),
          SuggestedHabit(
            title: 'Take a 10-minute walk',
            category: 'health',
            frequencyType: 'daily',
          ),
        ],
      ),
    ];
  }

  @override
  Future<void> completeOnboarding({
    required OnboardingData data,
    required List<SuggestedIdentity> chosenIdentities,
  }) async {
    final userId = SupabaseService.currentUser?.id;

    if (userId == null) {
      throw StateError(
        'Cannot complete onboarding without an authenticated user.',
      );
    }

    await _client.from('user_profiles').upsert({
      'user_id': userId,
      'age': data.age,
      'gender': data.gender,
      'occupation': data.occupation,
      'wake_up_time': data.wakeUpTime,
      'sleep_time': data.sleepTime,
      'preferred_language': data.preferredLanguage,
      'onboarding_completed': true,
      'onboarding_data': data.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    if (data.name != null) {
      await _client
          .from('users')
          .update({'display_name': data.name})
          .eq('id', userId);
    }

    if (data.notificationTimes.isNotEmpty) {
      await _client.from('user_settings').upsert({
        'user_id': userId,
        'morning_mission_time': data.notificationTimes.first,
        'daily_checkin_time': data.notificationTimes.length > 1
            ? data.notificationTimes[1]
            : '20:00:00',
      });
    }

    for (final entry in data.lifePriorities.entries) {
      await _client.from('life_areas').upsert({
        'user_id': userId,
        'area_key': entry.key,
        'current_score': entry.value,
        'target_score': 10,
      }, onConflict: 'user_id,area_key');
    }

    final categories = await _client
        .from('habit_categories')
        .select('id, key');

    final categoryIdByKey = {
      for (final c in categories)
        c['key'] as String: c['id'] as String,
    };

    for (final identity in chosenIdentities) {
      final identityRow = await _client
          .from('identities')
          .insert({
            'user_id': userId,
            'title': identity.title,
            'description': identity.description,
            'icon': identity.icon,
          })
          .select('id')
          .single();

      final identityId = identityRow['id'] as String;

      for (final habit in identity.habits) {
        final categoryId =
            categoryIdByKey[habit.category] ??
            categoryIdByKey['custom'];

        await _client.from('habits').insert({
          'user_id': userId,
          'identity_id': identityId,
          'category_id': categoryId,
          'title': habit.title,
          'frequency_type': habit.frequencyType,
          'frequency_config': habit.timesPerWeek != null
              ? {'times_per_week': habit.timesPerWeek}
              : {},
          'priority': 'medium',
        });
      }
    }

    await _client.from('growth_tree_state').upsert({
      'user_id': userId,
      'tree_stage': 1,
      'health': 100,
      'last_activity_date':
          DateTime.now().toIso8601String().split('T').first,
    });

    await _client.from('user_levels').upsert({
      'user_id': userId,
      'xp': 0,
      'level': 1,
    });
  }
}
