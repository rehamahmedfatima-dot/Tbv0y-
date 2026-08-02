import 'journal_entry.dart';

abstract class JournalRepository {
  Future<List<JournalEntry>> loadEntries({int limit = 50});

  Future<JournalEntry> createEntry({
    required JournalEntryType type,
    required String content,
    String? moodAtEntry,
  });

  Future<void> updateEntry(String id, String content);
  Future<void> deleteEntry(String id);

  /// Summarizes a single entry with Gemini and stores the summary.
  Future<String> summarizeEntry(String id);

  /// Analyzes the mood across recent journal entries (used by Mood Tracker
  /// and the AI Coach's weekly review).
  Future<String> analyzeMoodPatterns();
}
