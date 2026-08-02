class Skill {
  final String id;
  final String title;
  final String? category;
  final String level; // beginner|intermediate|advanced|expert
  final double hoursLogged;
  final DateTime? startedAt;

  const Skill({
    required this.id,
    required this.title,
    this.category,
    required this.level,
    required this.hoursLogged,
    this.startedAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String?,
        level: json['level'] as String? ?? 'beginner',
        hoursLogged: (json['hours_logged'] as num?)?.toDouble() ?? 0,
        startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      );
}
