import '../../../core/config/env_config.dart';

class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Maps raw Supabase/Google/Apple errors to safe, user-facing messages.
class AuthExceptionMapper {
  static AuthException map(Object error) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('invalid login credentials') || raw.contains('invalid_credentials')) {
      return AuthException('Incorrect email or password. [debug: $error]', code: 'invalid_credentials');
    }
    if (raw.contains('user already registered') || raw.contains('already exists')) {
      return AuthException('An account with this email already exists. [debug: $error]', code: 'user_exists');
    }
    if (raw.contains('email not confirmed')) {
      return AuthException('Please verify your email before signing in. [debug: $error]', code: 'email_unconfirmed');
    }
    if (raw.contains('weak_password') || raw.contains('password should be at least')) {
      return AuthException('Password must be at least 8 characters. [debug: $error]', code: 'weak_password');
    }
    if (raw.contains('network') || raw.contains('socket')) {
      return AuthException('Network error. Check your connection and try again. [debug: $error]', code: 'network_error');
    }
    if (raw.contains('cancel')) {
      return AuthException('Sign-in was cancelled. [debug: $error]', code: 'cancelled');
    }
    if (raw.contains('otp') && raw.contains('expired')) {
      return AuthException('This code has expired. Request a new one. [debug: $error]', code: 'otp_expired');
    }
    if (raw.contains('otp')) {
      return AuthException('Invalid verification code. [debug: $error]', code: 'invalid_otp');
    }

    // TEMPORARY — showing the raw error AND the actual compiled-in
    // Supabase URL, so we can see exactly what value made it into this
    // build (GitHub never shows secret values back, so this is the only
    // way to confirm it landed correctly).
    return AuthException(
      'Unmapped error: $error [SUPABASE_URL used: ${EnvConfig.supabaseUrl}]',
      code: 'unknown',
    );
  }
}
