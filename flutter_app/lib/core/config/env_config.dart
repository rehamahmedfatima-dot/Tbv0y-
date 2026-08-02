/// Centralized environment configuration.
/// Values are loaded from a `.env` file at app startup via flutter_dotenv —
/// never hardcode keys here or commit `.env` to version control.
class EnvConfig {
  EnvConfig._();

  static late String supabaseUrl;
  static late String supabaseAnonKey;
  static late String geminiApiKey;
  static late String backendApiUrl;

  static void load(Map<String, String> env) {
    supabaseUrl = _require(env, 'SUPABASE_URL');
    supabaseAnonKey = _require(env, 'SUPABASE_ANON_KEY');
    geminiApiKey = _require(env, 'GEMINI_API_KEY');
    backendApiUrl = _require(env, 'BACKEND_API_URL');
  }

  static String _require(Map<String, String> env, String key) {
    final value = env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required env var: $key. Add it to your .env file '
        '(see .env.example).',
      );
    }
    return value;
  }
}
