import 'coach_message.dart';

abstract class CoachRepository {
  /// Gets today's general conversation, creating one if it doesn't exist yet.
  Future<CoachConversation> getOrCreateTodayConversation();

  Future<List<CoachMessage>> loadMessages(String conversationId);

  /// Sends a user message, gets Gemini's reply (with full user context:
  /// habits, discipline score, mood, journal), stores both, returns the
  /// assistant's reply.
  Future<CoachMessage> sendMessage({
    required String conversationId,
    required String userText,
  });

  /// Generates a structured weekly review conversation summarizing the
  /// last 7 days of habits/mood/discipline data.
  Future<CoachConversation> generateWeeklyReview();

  /// Generates a structured monthly report.
  Future<CoachConversation> generateMonthlyReport();
}
