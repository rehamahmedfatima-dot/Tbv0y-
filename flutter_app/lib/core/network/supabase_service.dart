import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

/// Wraps Supabase initialization so the rest of the app just calls
/// `SupabaseService.client` without worrying about setup order.
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
}
