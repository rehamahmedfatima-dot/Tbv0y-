class Challenge {
  final String id;
  final String title;
  final String? description;
  final int durationDays;
  final bool isGlobal;

  // Participation info (null if the user hasn't joined)
  final DateTime? startDate;
  final int currentDay;
  final String? status; // active|completed|failed|abandoned

  const Challenge({
    required this.id,
    required this.title,
    this.description,
    required this.durationDays,
    required this.isGlobal,
    this.startDate,
    this.currentDay = 0,
    this.status,
  });

  bool get isJoined => status != null;
  double get progress => durationDays == 0 ? 0 : (currentDay / durationDays).clamp(0, 1).toDouble();

  factory Challenge.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? participation}) => Challenge(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        durationDays: json['duration_days'] as int,
        isGlobal: json['is_global'] as bool? ?? false,
        startDate: participation?['start_date'] != null ? DateTime.parse(participation!['start_date']) : null,
        currentDay: participation?['current_day'] as int? ?? 0,
        status: participation?['status'] as String?,
      );
}
