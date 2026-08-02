import '../../../core/network/supabase_service.dart';
import '../domain/skill.dart';

abstract class SkillsRepository {
  Future<List<Skill>> loadSkills();
  Future<void> addSkill(String title, String? category);
  Future<void> logSession(String skillId, int minutes, {String? note});
  Future<void> updateLevel(String skillId, String level);
}

class SupabaseSkillsRepository implements SkillsRepository {
  final _client = SupabaseService.client;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<List<Skill>> loadSkills() async {
    final rows = await _client
        .from('skills')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Skill.fromJson(r)).toList();
  }

  @override
  Future<void> addSkill(String title, String? category) async {
    await _client.from('skills').insert({
      'user_id': _userId,
      'title': title,
      'category': category,
      'started_at': DateTime.now().toIso8601String().split('T').first,
    });
  }

  @override
  Future<void> logSession(String skillId, int minutes, {String? note}) async {
    await _client.from('skill_sessions').insert({
      'skill_id': skillId,
      'session_date': DateTime.now().toIso8601String().split('T').first,
      'minutes': minutes,
      'note': note,
    });

    final skill = await _client.from('skills').select('hours_logged').eq('id', skillId).single();
    final newHours = (skill['hours_logged'] as num).toDouble() + (minutes / 60);
    await _client.from('skills').update({'hours_logged': newHours}).eq('id', skillId);
  }

  @override
  Future<void> updateLevel(String skillId, String level) async {
    await _client.from('skills').update({'level': level}).eq('id', skillId);
  }
}
