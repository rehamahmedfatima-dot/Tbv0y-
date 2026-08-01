enum ConversationType { general, dailyCheckin, weeklyReview, monthlyReport }

String conversationTypeToString(ConversationType t) {
  switch (t) {
    case ConversationType.dailyCheckin:
      return 'daily_checkin';
    case ConversationType.weeklyReview:
      return 'weekly_review';
    case ConversationType.monthlyReport:
      return 'monthly_report';
    case ConversationType.general:
      return 'general';
  }
}

class CoachConversation {
  final String id;
  final String? title;
  final ConversationType type;
  final DateTime createdAt;

  const CoachConversation({
    required this.id,
    this.title,
    required this.type,
    required this.createdAt,
  });

  factory CoachConversation.fromJson(Map<String, dynamic> json) => CoachConversation(
        id: json['id'] as String,
        title: json['title'] as String?,
        type: ConversationType.values.firstWhere(
          (t) => conversationTypeToString(t) == (json['conversation_type'] as String? ?? 'general'),
          orElse: () => ConversationType.general,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class CoachMessage {
  final String id;
  final String conversationId;
  final bool isUser; // role == 'user'
  final String content;
  final DateTime createdAt;

  const CoachMessage({
    required this.id,
    required this.conversationId,
    required this.isUser,
    required this.content,
    required this.createdAt,
  });

  factory CoachMessage.fromJson(Map<String, dynamic> json) => CoachMessage(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        isUser: (json['role'] as String) == 'user',
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
