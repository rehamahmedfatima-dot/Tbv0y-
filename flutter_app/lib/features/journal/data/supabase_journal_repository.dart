import '../../../core/ai/gemini_service.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

class SupabaseJournalRepository implements JournalRepository {
  final _client = SupabaseService.client;
  final _ai = GeminiService.instance;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<List<JournalEntry>> loadEntries({int limit = 50}) async {
    final rows = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', _userId)
        .order('entry_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).map((r) => JournalEntry.fromJson(r)).toList();
  }

  @override
  Future<JournalEntry> createEntry({
    required JournalEntryType type,
    required String content,
    String? moodAtEntry,
  }) async {
    final row = await _client
        .from('journal_entries')
        .insert({
          'user_id': _userId,
          'entry_date': DateTime.now().toIso8601String().split('T').first,
          'entry_type': journalTypeToString(type),
          'content': content,
          'mood_at_entry': moodAtEntry,
        })
        .select()
        .single();
    return JournalEntry.fromJson(row);
  }

  @override
  Future<void> updateEntry(String id, String content) async {
    await _client.from('journal_entries').update({
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _client.from('journal_entries').delete().eq('id', id);
  }

  @override
  Future<String> summarizeEntry(String id) async {
    final row = await _client.from('journal_entries').select('content').eq('id', id).single();
    final content = row['content'] as String? ?? '';

    if (content.trim().length < 40) return content; // too short to bother summarizing

    final summary = await _ai.generateText(
      'Summarize this journal entry in one warm, reflective sentence '
      '(under 20 words), written as if gently reflecting the writer\'s '
      'own thought back to them:\n\n$content',
    );

    await _client.from('journal_entries').update({'ai_summary': summary}).eq('id', id);
    return summary;
  }

  @override
  Future<String> analyzeMoodPatterns() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 14)).toIso8601String().split('T').first;
    final rows = await _client
        .from('journal_entries')
        .select('entry_date, mood_at_entry, content')
        .eq('user_id', _userId)
        .gte('entry_date', weekAgo)
        .order('entry_date');

    if ((rows as List).isEmpty) {
      return 'Write a few journal entries and I\'ll start spotting patterns for you.';
    }

    final summaryLines = rows
        .map((r) => '${r['entry_date']}: mood=${r['mood_at_entry'] ?? 'n/a'}')
        .join('\n');

    return _ai.generateText(
      'Based on these mood-tagged journal dates over the last 2 weeks, '
      'identify one gentle, specific pattern (e.g. a day of week, a trend) '
      'in 1-2 sentences. Be encouraging, not clinical:\n\n$summaryLines',
    );
  }
}
