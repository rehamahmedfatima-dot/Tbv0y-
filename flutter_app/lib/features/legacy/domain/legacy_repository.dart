import 'legacy_profile.dart';

abstract class LegacyRepository {
  Future<LegacyProfile> load();
  Future<void> save(LegacyProfile profile);

  /// Checks the user's active habits/goals against their stated mission
  /// and values, and returns a short AI note on alignment (or gentle
  /// suggestions if something's drifted).
  Future<String> checkAlignment();
}
