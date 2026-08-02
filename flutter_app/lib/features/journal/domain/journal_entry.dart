enum JournalEntryType { morning, evening, gratitude, lesson, freeform }

String journalTypeToString(JournalEntryType t) => t.name;

JournalEntryType journalTypeFromString(String s) =>
    JournalEntryType.values.firstWhere((t) => t.name == s, orElse: () => JournalEntryType.freeform);

String journalTypeLabel(JournalEntryType t) {
  switch (t) {
    case JournalEntryType.morning:
      return 'Morning Journal';
    case JournalEntryType.evening:
      return 'Evening Reflection';
    case JournalEntryType.gratitude:
      return 'Gratitude';
    case JournalEntryType.lesson:
      return 'Lesson Learned';
    case JournalEntryType.freeform:
      return 'Free Write';
  }
}

String journalTypePrompt(JournalEntryType t) {
  switch (t) {
    case JournalEntryType.morning:
      return "What's your intention for today?";
    case JournalEntryType.evening:
      return 'How did today go? What would you do differently?';
    case JournalEntryType.gratitude:
      return 'What are you grateful for right now?';
    case JournalEntryType.lesson:
      return 'What did you learn today?';
    case JournalEntryType.freeform:
      return "What's on your mind?";
  }
}

class JournalEntry {
  final String id;
  final DateTime entryDate;
  final JournalEntryType type;
  final String content;
  final String? aiSummary;
  final String? moodAtEntry;
  final List<String> tags;
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.entryDate,
    required this.type,
    required this.content,
    this.aiSummary,
    this.moodAtEntry,
    this.tags = const [],
    required this.createdAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        entryDate: DateTime.parse(json['entry_date'] as String),
        type: journalTypeFromString(json['entry_type'] as String? ?? 'freeform'),
        content: json['content'] as String? ?? '',
        aiSummary: json['ai_summary'] as String?,
        moodAtEntry: json['mood_at_entry'] as String?,
        tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
