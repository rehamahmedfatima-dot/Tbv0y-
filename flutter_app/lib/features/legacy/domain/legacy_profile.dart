class LegacyProfile {
  final String? missionStatement;
  final List<String> coreValues;
  final String? vision;
  final String? lifePurpose;
  final List<String> dreams;

  const LegacyProfile({
    this.missionStatement,
    this.coreValues = const [],
    this.vision,
    this.lifePurpose,
    this.dreams = const [],
  });

  factory LegacyProfile.fromJson(Map<String, dynamic> json) => LegacyProfile(
        missionStatement: json['mission_statement'] as String?,
        coreValues: (json['core_values'] as List<dynamic>? ?? []).cast<String>(),
        vision: json['vision'] as String?,
        lifePurpose: json['life_purpose'] as String?,
        dreams: (json['dreams'] as List<dynamic>? ?? []).cast<String>(),
      );
}
