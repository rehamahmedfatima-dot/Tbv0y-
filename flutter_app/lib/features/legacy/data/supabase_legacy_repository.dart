import '../../../core/ai/gemini_service.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/legacy_profile.dart';
import '../domain/legacy_repository.dart';

class SupabaseLegacyRepository implements LegacyRepository {
  final _client = SupabaseService.client;
  final _ai = GeminiService.instance;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<LegacyProfile> load() async {
    final row = await _client.from('legacy_profiles').select().eq('user_id', _userId).maybeSingle();
    return row != null ? LegacyProfile.fromJson(row) : const LegacyProfile();
  }

  @override
  Future<void> save(LegacyProfile profile) async {
    await _client.from('legacy_profiles').upsert({
      'user_id': _userId,
      'mission_statement': profile.missionStatement,
      'core_values': profile.coreValues,
      'vision': profile.vision,
      'life_purpose': profile.lifePurpose,
      'dreams': profile.dreams,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<String> checkAlignment() async {
    final legacy = await load();
    if (legacy.missionStatement == null && legacy.coreValues.isEmpty) {
      return 'Set your mission and core values first, and I\'ll check how well your daily habits support them.';
    }

    final habits = await _client.from('habits').select('title').eq('user_id', _userId).eq('is_active', true);
    final habitTitles = (habits as List).map((h) => h['title']).join(', ');

    final prompt = '''
User's life mission: "${legacy.missionStatement ?? 'not set'}"
Core values: ${legacy.coreValues.join(', ')}
Their current active habits: ${habitTitles.isEmpty ? 'none' : habitTitles}

In 2 short, warm sentences, tell them how well their daily habits align
with their stated mission and values, and one gentle suggestion if
something's missing.
''';

    return _ai.generateText(prompt);
  }
}
