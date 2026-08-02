enum GoalType { shortTerm, longTerm }
enum GoalStatus { active, completed, paused, abandoned }

class Milestone {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? dueDate;
  final int sortOrder;

  const Milestone({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    this.sortOrder = 0,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['is_completed'] as bool? ?? false,
        dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

class Goal {
  final String id;
  final String title;
  final String? description;
  final GoalType type;
  final DateTime? targetDate;
  final GoalStatus status;
  final double progressPercent;
  final List<String> aiRoadmap;
  final List<Milestone> milestones;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.targetDate,
    required this.status,
    this.progressPercent = 0,
    this.aiRoadmap = const [],
    this.milestones = const [],
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        type: (json['goal_type'] as String? ?? 'short_term') == 'long_term'
            ? GoalType.longTerm
            : GoalType.shortTerm,
        targetDate: json['target_date'] != null ? DateTime.parse(json['target_date'] as String) : null,
        status: GoalStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String? ?? 'active').replaceAll('_', ''),
          orElse: () => GoalStatus.active,
        ),
        progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
        aiRoadmap: (json['ai_roadmap'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        milestones: (json['milestones'] as List<dynamic>? ?? [])
            .map((m) => Milestone.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
