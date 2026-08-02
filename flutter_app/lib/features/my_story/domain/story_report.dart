class StoryReport {
  final int year;
  final String title;
  final String openingReflection;
  final List<String> highlights;
  final List<String> strengths;
  final List<String> suggestedImprovements;
  final String beforeAfter;
  final String closingMotivation;

  const StoryReport({
    required this.year,
    required this.title,
    required this.openingReflection,
    required this.highlights,
    required this.strengths,
    required this.suggestedImprovements,
    required this.beforeAfter,
    required this.closingMotivation,
  });

  factory StoryReport.fromContentJson(int year, String title, Map<String, dynamic> content) => StoryReport(
        year: year,
        title: title,
        openingReflection: content['opening_reflection'] as String? ?? '',
        highlights: (content['highlights'] as List<dynamic>? ?? []).cast<String>(),
        strengths: (content['strengths'] as List<dynamic>? ?? []).cast<String>(),
        suggestedImprovements: (content['suggested_improvements'] as List<dynamic>? ?? []).cast<String>(),
        beforeAfter: content['before_after'] as String? ?? '',
        closingMotivation: content['closing_motivation'] as String? ?? '',
      );

  Map<String, dynamic> toContentJson() => {
        'opening_reflection': openingReflection,
        'highlights': highlights,
        'strengths': strengths,
        'suggested_improvements': suggestedImprovements,
        'before_after': beforeAfter,
        'closing_motivation': closingMotivation,
      };
}
