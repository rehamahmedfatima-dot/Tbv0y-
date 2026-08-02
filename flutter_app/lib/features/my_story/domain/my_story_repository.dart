import 'story_report.dart';

abstract class MyStoryRepository {
  /// Loads the cached report for the given year if one exists.
  Future<StoryReport?> loadReport(int year);

  /// Gathers the year's data (habits, streaks, mood, journal, goals,
  /// books, achievements) and asks Gemini to write "The Story of Your
  /// Best Version", then caches it.
  Future<StoryReport> generateReport(int year);
}
