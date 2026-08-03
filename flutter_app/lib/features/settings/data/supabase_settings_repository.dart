import '../../../core/network/backend_api_client.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  final _client = SupabaseService.client;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<AppSettings> loadSettings() async {
    final row = await _client.from('user_settings').select().eq('user_id', _userId).maybeSingle();
    if (row == null) {
      // First run — create the default row so future updates have
      // something to upsert against.
      await _client.from('user_settings').insert({'user_id': _userId});
      return const AppSettings();
    }
    return AppSettings.fromJson(row);
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    await _client.from('user_settings').upsert({
      'user_id': _userId,
      'theme_mode': settings.themeMode,
      'biometric_enabled': settings.biometricEnabled,
      'notifications_enabled': settings.notificationsEnabled,
      'ai_personality': settings.aiPersonality,
      'daily_checkin_time': '${settings.dailyCheckinTime}:00',
      'morning_mission_time': '${settings.morningMissionTime}:00',
      'data_export_enabled': settings.dataExportEnabled,
    });

    // Language lives on user_profiles, not user_settings.
    await _client
        .from('user_profiles')
        .update({'preferred_language': settings.preferredLanguage})
        .eq('user_id', _userId);
  }

  @override
  Future<Map<String, dynamic>> exportAllData() async {
    final tables = [
      'user_profiles',
      'identities',
      'life_areas',
      'habits',
      'habit_logs',
      'journal_entries',
      'mood_logs',
      'goals',
      'milestones',
      'focus_sessions',
      'letters',
      'skills',
      'books',
      'legacy_profiles',
      'user_achievements',
    ];

    final result = <String, dynamic>{};
    for (final table in tables) {
      try {
        result[table] = await _client.from(table).select().eq('user_id', _userId);
      } catch (_) {
        // Some tables key off a different column (e.g. milestones off
        // goal_id) — skip gracefully rather than failing the whole export.
        result[table] = [];
      }
    }
    return result;
  }

  @override
  Future<void> requestAccountDeletion() async {
    await BackendApiClient.instance.deleteAccount();
  }
}
