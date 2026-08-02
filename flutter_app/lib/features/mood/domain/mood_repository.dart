import 'mood_entry.dart';

abstract class MoodRepository {
  Future<List<MoodLog>> loadHistory({int days = 30});

  Future<void> logMood({
    required String mood,
    required int score,
    List<String> triggers = const [],
    String? note,
  });

  /// AI-suggested activities based on the most recent mood + recent patterns.
  Future<List<String>> suggestActivities();
}
