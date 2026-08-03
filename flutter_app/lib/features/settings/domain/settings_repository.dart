import 'app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> updateSettings(AppSettings settings);

  /// Exports all of the user's data as JSON (used for the CSV/PDF export
  /// and the "Export Data" settings action).
  Future<Map<String, dynamic>> exportAllData();

  Future<void> requestAccountDeletion();
}
