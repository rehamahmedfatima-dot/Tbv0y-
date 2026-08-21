import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

/// Wraps Supabase initialization so the rest of the app just calls
/// `SupabaseService.client` without worrying about setup order.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static Future<void>? _initializationFuture;

  /// Initializes Supabase exactly once.
  ///
  /// A timeout prevents the application startup from waiting indefinitely
  /// if the Supabase initialization gets stuck.
  static Future<void> initialize() {
    if (_initialized) {
      return Future.value();
    }

    return _initializationFuture ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Supabase initialization timed out after 15 seconds.',
          );
        },
      );

      _initialized = true;
    } catch (_) {
      // Allow a future retry if initialization failed.
      _initializationFuture = null;
      rethrow;
    }
  }

  static bool get isInitialized => _initialized;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'SupabaseService has not been initialized. '
        'Call SupabaseService.initialize() before accessing the client.',
      );
    }

    return Supabase.instance.client;
  }

  static GoTrueClient get auth => client.auth;

  static User? get currentUser => client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;
}
