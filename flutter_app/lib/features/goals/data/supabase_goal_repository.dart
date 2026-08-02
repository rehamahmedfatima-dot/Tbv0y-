import 'dart:convert';
import '../../../core/ai/gemini_service.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/goal.dart';
import '../domain/goal_repository.dart';

class SupabaseGoalRepository implements GoalRepository {
  final _client = SupabaseService.client;
  final _ai = GeminiService.instance;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<List<Goal>> loadGoals() async {
    final rows = await _client
        .from('goals')
        .select('*, milestones(*)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Goal.fromJson(r)).toList();
  }

  @override
  Future<Goal> createGoal({
    required String title,
    String? description,
    required GoalType type,
    DateTime? targetDate,
  }) async {
    final row = await _client
        .from('goals')
        .insert({
          'user_id': _userId,
          'title': title,
          'description': description,
          'goal_type': type == GoalType.longTerm ? 'long_term' : 'short_term',
          'target_date': targetDate?.toIso8601String().split('T').first,
        })
        .select()
        .single();
    return Goal.fromJson(row);
  }

  @override
  Future<void> updateProgress(String goalId, double progressPercent) async {
    await _client.from('goals').update({'progress_percent': progressPercent}).eq('id', goalId);
  }

  @override
  Future<void> markCompleted(String goalId) async {
    await _client.from('goals').update({
      'status': 'completed',
      'progress_percent': 100,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', goalId);
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    await _client.from('goals').delete().eq('id', goalId);
  }

  @override
  Future<void> toggleMilestone(String milestoneId, bool completed) async {
    await _client.from('milestones').update({
      'is_completed': completed,
      'completed_at': completed ? DateTime.now().toIso8601String() : null,
    }).eq('id', milestoneId);

    // Recompute parent goal's progress from milestone completion ratio.
    final milestone = await _client.from('milestones').select('goal_id').eq('id', milestoneId).single();
    final goalId = milestone['goal_id'] as String;
    final all = await _client.from('milestones').select('is_completed').eq('goal_id', goalId);
    final list = all as List;
    if (list.isNotEmpty) {
      final done = list.where((m) => m['is_completed'] == true).length;
      await updateProgress(goalId, (done / list.length) * 100);
    }
  }

  @override
  Future<List<String>> generateRoadmap(String goalId) async {
    final goal = await _client.from('goals').select('title, description').eq('id', goalId).single();

    final prompt = '''
Break this goal into 4-6 concrete, sequential milestones a person could
actually check off. Goal: "${goal['title']}". ${goal['description'] != null ? 'Details: ${goal['description']}' : ''}

Respond with ONLY a JSON array of short milestone titles (under 8 words each), e.g.
["Research 3 options", "Set a weekly budget", "Complete first session"]
''';

    List<String> milestones;
    try {
      final raw = await _ai.generateJson(prompt);
      final list = jsonDecode(raw);
      milestones = list is List ? list.cast<String>() : [];
    } catch (_) {
      milestones = [];
    }

    if (milestones.isEmpty) return [];

    await _client.from('goals').update({'ai_roadmap': milestones}).eq('id', goalId);

    for (int i = 0; i < milestones.length; i++) {
      await _client.from('milestones').insert({
        'goal_id': goalId,
        'title': milestones[i],
        'sort_order': i,
      });
    }

    return milestones;
  }

  @override
  Future<List<String>> suggestNextGoals() async {
    final identities = await _client.from('identities').select('title').eq('user_id', _userId).limit(5);
    final activeGoals = await _client.from('goals').select('title').eq('user_id', _userId).eq('status', 'active');

    final identityTitles = (identities as List).map((i) => i['title']).join(', ');
    final activeGoalTitles = (activeGoals as List).map((g) => g['title']).join(', ');

    final prompt = '''
User's identities they're building toward: ${identityTitles.isEmpty ? 'none set' : identityTitles}.
Their current active goals: ${activeGoalTitles.isEmpty ? 'none' : activeGoalTitles}.
Suggest 3 new, specific, achievable goals that would complement (not
duplicate) what they're already doing. Respond with ONLY a JSON array of
3 short goal titles.
''';

    try {
      final raw = await _ai.generateJson(prompt);
      final list = jsonDecode(raw);
      return list is List ? list.cast<String>() : [];
    } catch (_) {
      return const [];
    }
  }
}
