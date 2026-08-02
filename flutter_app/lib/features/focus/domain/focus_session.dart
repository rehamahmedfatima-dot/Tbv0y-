enum FocusSessionType { pomodoro, deepWork, forest }

String focusTypeToString(FocusSessionType t) {
  switch (t) {
    case FocusSessionType.deepWork:
      return 'deep_work';
    case FocusSessionType.forest:
      return 'forest';
    case FocusSessionType.pomodoro:
      return 'pomodoro';
  }
}

const focusDurationsMinutes = {
  FocusSessionType.pomodoro: 25,
  FocusSessionType.deepWork: 90,
  FocusSessionType.forest: 45,
};

class FocusSession {
  final String id;
  final FocusSessionType type;
  final int durationMinutes;
  final bool completed;
  final bool interrupted;
  final DateTime startedAt;
  final DateTime? endedAt;

  const FocusSession({
    required this.id,
    required this.type,
    required this.durationMinutes,
    required this.completed,
    required this.interrupted,
    required this.startedAt,
    this.endedAt,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'] as String,
        type: FocusSessionType.values.firstWhere(
          (t) => focusTypeToString(t) == (json['session_type'] as String? ?? 'pomodoro'),
          orElse: () => FocusSessionType.pomodoro,
        ),
        durationMinutes: json['duration_minutes'] as int,
        completed: json['completed'] as bool? ?? false,
        interrupted: json['interrupted'] as bool? ?? false,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      );
}
