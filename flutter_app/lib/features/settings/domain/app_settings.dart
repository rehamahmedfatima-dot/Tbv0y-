class AppSettings {
  final String themeMode; // light | dark | system
  final bool biometricEnabled;
  final bool notificationsEnabled;
  final String aiPersonality; // gentle | balanced | tough_love
  final String dailyCheckinTime;
  final String morningMissionTime;
  final bool dataExportEnabled;
  final String preferredLanguage;

  const AppSettings({
    this.themeMode = 'system',
    this.biometricEnabled = false,
    this.notificationsEnabled = true,
    this.aiPersonality = 'balanced',
    this.dailyCheckinTime = '20:00',
    this.morningMissionTime = '07:00',
    this.dataExportEnabled = true,
    this.preferredLanguage = 'en',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: json['theme_mode'] as String? ?? 'system',
        biometricEnabled: json['biometric_enabled'] as bool? ?? false,
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
        aiPersonality: json['ai_personality'] as String? ?? 'balanced',
        dailyCheckinTime: (json['daily_checkin_time'] as String? ?? '20:00:00').substring(0, 5),
        morningMissionTime: (json['morning_mission_time'] as String? ?? '07:00:00').substring(0, 5),
        dataExportEnabled: json['data_export_enabled'] as bool? ?? true,
        preferredLanguage: json['preferred_language'] as String? ?? 'en',
      );

  AppSettings copyWith({
    String? themeMode,
    bool? biometricEnabled,
    bool? notificationsEnabled,
    String? aiPersonality,
    String? dailyCheckinTime,
    String? morningMissionTime,
    bool? dataExportEnabled,
    String? preferredLanguage,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      aiPersonality: aiPersonality ?? this.aiPersonality,
      dailyCheckinTime: dailyCheckinTime ?? this.dailyCheckinTime,
      morningMissionTime: morningMissionTime ?? this.morningMissionTime,
      dataExportEnabled: dataExportEnabled ?? this.dataExportEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
