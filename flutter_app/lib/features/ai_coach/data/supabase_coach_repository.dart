import 'package:google_generative_ai/google_generative_ai.dart' show Content, TextPart;
import '../../../core/ai/gemini_service.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/coach_message.dart';
import '../domain/coach_repository.dart';

class SupabaseCoachRepository implements CoachRepository {
  final _client = SupabaseService.client;
  final _ai = GeminiService.instance;

  String get _userId => SupabaseService.currentUser!.id;

  Future<String> _buildUserContext() async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final habits = await _client
        .from('habits')
        .select('title, habit_streaks(current_streak)')
        .eq('user_id', _userId)
        .eq('is_active', true)
        .limit(15);

    final scoreRow = await _client
        .from('discipline_scores')
        .select('overall_score')
        .eq('user_id', _userId)
        .eq('score_date', today)
        .maybeSingle();

    final moodRow = await _client
        .from('mood_logs')
        .select('mood')
        .eq('user_id', _userId)
        .eq('log_date', today)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final profile = await _client
        .from('user_profiles')
        .select('onboarding_data')
        .eq('user_id', _userId)
        .maybeSingle();

    final habitsList = (habits as List)
        .map((h) => '${h['title']} (streak: ${h['habit_streaks']?['current_streak'] ?? 0})')
        .join(', ');

    return '''
User context (use this to personalize your response, don't just repeat it back):
- Active habits: ${habitsList.isEmpty ? 'none yet' : habitsList}
- Today's discipline score: ${scoreRow?['overall_score'] ?? 'not calculated yet'}/100
- Today's mood: ${moodRow?['mood'] ?? 'not logged'}
- Onboarding answers: ${profile?['onboarding_data'] ?? '{}'}
''';
  }

  static const _systemInstruction = '''
You are the AI Coach inside TBVOY, a personal growth app ("The Best Version
Of Yourself"). You are warm, direct, and practical — like a good coach, not
a generic chatbot. You know the user's habits, discipline score, and mood
from the context provided each turn. Keep replies concise (2-5 sentences
unless asked for detail), give one concrete next action when relevant, and
never be preachy or repeat generic motivational quotes. Never diagnose
mental health conditions — if the user describes something serious, gently
suggest a professional.
''';

  @override
  Future<CoachConversation> getOrCreateTodayConversation() async {
    final startOfDay = DateTime.now().toUtc();
    final todayStart = DateTime(startOfDay.year, startOfDay.month, startOfDay.day).toIso8601String();

    final existing = await _client
        .from('ai_conversations')
        .select()
        .eq('user_id', _userId)
        .eq('conversation_type', 'general')
        .gte('created_at', todayStart)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) return CoachConversation.fromJson(existing);

    final created = await _client
        .from('ai_conversations')
        .insert({'user_id': _userId, 'conversation_type': 'general', 'title': 'Chat with your Coach'})
        .select()
        .single();

    return CoachConversation.fromJson(created);
  }

  @override
  Future<List<CoachMessage>> loadMessages(String conversationId) async {
    final rows = await _client
        .from('ai_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (rows as List).map((r) => CoachMessage.fromJson(r)).toList();
  }

  @override
  Future<CoachMessage> sendMessage({required String conversationId, required String userText}) async {
    // Load prior turns BEFORE inserting the new one, so we can seed the
    // chat's history correctly then send only the new message once.
    final priorMessages = await loadMessages(conversationId);

    await _client.from('ai_messages').insert({
      'conversation_id': conversationId,
      'role': 'user',
      'content': userText,
    });

    final history = [
      for (final m in priorMessages)
        m.isUser ? Content.text(m.content) : Content.model([TextPart(m.content)]),
    ];

    final context = await _buildUserContext();
    final chat = _ai.startChat(history: history, systemInstruction: '$_systemInstruction\n\n$context');

    final response = await chat.sendMessage(Content.text(userText));
    final replyText = response.text?.trim() ?? "I'm here — could you rephrase that?";

    final saved = await _client
        .from('ai_messages')
        .insert({'conversation_id': conversationId, 'role': 'assistant', 'content': replyText})
        .select()
        .single();

    return CoachMessage.fromJson(saved);
  }

  @override
  Future<CoachConversation> generateWeeklyReview() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T').first;

    final scores = await _client
        .from('discipline_scores')
        .select('score_date, overall_score')
        .eq('user_id', _userId)
        .gte('score_date', weekAgo)
        .order('score_date');

    final logs = await _client
        .from('habit_logs')
        .select('completed, habits(title)')
        .eq('user_id', _userId)
        .gte('log_date', weekAgo);

    final avgScore = (scores as List).isEmpty
        ? 0
        : (scores as List).map((s) => (s['overall_score'] as num)).reduce((a, b) => a + b) /
            (scores as List).length;
    final completedCount = (logs as List).where((l) => l['completed'] == true).length;

    final prompt = '''
Write a warm, honest weekly review for a TBVOY user based on this data:
- Average discipline score this week: ${avgScore.toStringAsFixed(0)}/100
- Habit check-ins completed: $completedCount out of ${(logs).length}
- Daily scores: ${(scores).map((s) => s['overall_score']).join(', ')}

Structure: one sentence celebrating a real strength, one honest observation
about what slipped, one specific suggestion for next week. Keep it under
120 words, second person, encouraging but not saccharine.
''';

    final reviewText = await _ai.generateText(prompt, systemInstruction: _systemInstruction);

    final conversation = await _client
        .from('ai_conversations')
        .insert({'user_id': _userId, 'conversation_type': 'weekly_review', 'title': 'Your Weekly Review'})
        .select()
        .single();

    await _client.from('ai_messages').insert({
      'conversation_id': conversation['id'],
      'role': 'assistant',
      'content': reviewText,
    });

    return CoachConversation.fromJson(conversation);
  }

  @override
  Future<CoachConversation> generateMonthlyReport() async {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T').first;

    final scores = await _client
        .from('discipline_scores')
        .select('overall_score')
        .eq('user_id', _userId)
        .gte('score_date', monthAgo);

    final avgScore = (scores as List).isEmpty
        ? 0
        : (scores).map((s) => (s['overall_score'] as num)).reduce((a, b) => a + b) / scores.length;

    final prompt = '''
Write a monthly growth report for a TBVOY user. Average discipline score
over the last 30 days: ${avgScore.toStringAsFixed(0)}/100, based on
${scores.length} logged days.

Structure: a short "how this month went" paragraph, 2-3 bullet-style
sentences on patterns you notice, and one focus area for next month.
Keep it under 180 words total, warm and specific, second person.
''';

    final reportText = await _ai.generateText(prompt, systemInstruction: _systemInstruction);

    final conversation = await _client
        .from('ai_conversations')
        .insert({'user_id': _userId, 'conversation_type': 'monthly_report', 'title': 'Your Monthly Report'})
        .select()
        .single();

    await _client.from('ai_messages').insert({
      'conversation_id': conversation['id'],
      'role': 'assistant',
      'content': reportText,
    });

    return CoachConversation.fromJson(conversation);
  }
}
