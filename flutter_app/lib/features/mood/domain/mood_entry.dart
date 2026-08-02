const moodScores = {'great': 5, 'good': 4, 'neutral': 3, 'low': 2, 'bad': 1};
const moodEmojis = {'great': '😄', 'good': '🙂', 'neutral': '😐', 'low': '😕', 'bad': '😞'};

class MoodLog {
  final String id;
  final DateTime logDate;
  final String mood; // great|good|neutral|low|bad
  final int moodScore;
  final List<String> triggers;
  final String? note;

  const MoodLog({
    required this.id,
    required this.logDate,
    required this.mood,
    required this.moodScore,
    this.triggers = const [],
    this.note,
  });

  factory MoodLog.fromJson(Map<String, dynamic> json) => MoodLog(
        id: json['id'] as String,
        logDate: DateTime.parse(json['log_date'] as String),
        mood: json['mood'] as String,
        moodScore: json['mood_score'] as int? ?? (moodScores[json['mood']] ?? 3),
        triggers: (json['triggers'] as List<dynamic>? ?? []).cast<String>(),
        note: json['note'] as String?,
      );
}
