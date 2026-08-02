import '../../../core/network/supabase_service.dart';
import '../domain/challenge.dart';
import '../domain/challenge_repository.dart';

class SupabaseChallengeRepository implements ChallengeRepository {
  final _client = SupabaseService.client;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<List<Challenge>> loadChallenges() async {
    final challenges = await _client
        .from('challenges')
        .select()
        .or('is_global.eq.true,created_by.eq.$_userId')
        .order('created_at');

    final participations = await _client.from('challenge_participants').select().eq('user_id', _userId);
    final participationMap = {
      for (final p in (participations as List)) p['challenge_id'] as String: p as Map<String, dynamic>,
    };

    return (challenges as List)
        .map((c) => Challenge.fromJson(c, participation: participationMap[c['id']]))
        .toList();
  }

  @override
  Future<void> createCustomChallenge({
    required String title,
    String? description,
    required int durationDays,
  }) async {
    final row = await _client
        .from('challenges')
        .insert({
          'title': title,
          'description': description,
          'duration_days': durationDays,
          'is_global': false,
          'created_by': _userId,
        })
        .select('id')
        .single();
    await joinChallenge(row['id'] as String);
  }

  @override
  Future<void> joinChallenge(String challengeId) async {
    await _client.from('challenge_participants').upsert({
      'challenge_id': challengeId,
      'user_id': _userId,
      'start_date': DateTime.now().toIso8601String().split('T').first,
      'current_day': 0,
      'status': 'active',
    }, onConflict: 'challenge_id,user_id');
  }

  @override
  Future<void> markTodayDone(String challengeId) async {
    final row = await _client
        .from('challenge_participants')
        .select('current_day, challenges(duration_days)')
        .eq('challenge_id', challengeId)
        .eq('user_id', _userId)
        .single();

    final currentDay = (row['current_day'] as int) + 1;
    final durationDays = row['challenges']['duration_days'] as int;
    final completed = currentDay >= durationDays;

    await _client.from('challenge_participants').update({
      'current_day': currentDay,
      'status': completed ? 'completed' : 'active',
    }).eq('challenge_id', challengeId).eq('user_id', _userId);
  }

  @override
  Future<void> abandonChallenge(String challengeId) async {
    await _client
        .from('challenge_participants')
        .update({'status': 'abandoned'})
        .eq('challenge_id', challengeId)
        .eq('user_id', _userId);
  }
}
