class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Maps raw Supabase/Google/Apple errors to safe, user-facing messages.
/// Never surface raw provider error strings to the UI — they can leak
/// implementation details or be inconsistent between providers.
class AuthExceptionMapper {
  static AuthException map(Object error) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('invalid login credentials') || raw.contains('invalid_credentials')) {
      return const AuthException('Incorrect email or password.', code: 'invalid_credentials');
    }
    if (raw.contains('user already registered') || raw.contains('already exists')) {
      return const AuthException('An account with this email already exists.', code: 'user_exists');
    }
    if (raw.contains('email not confirmed')) {
      return const AuthException('Please verify your email before signing in.', code: 'email_unconfirmed');
    }
    if (raw.contains('weak_password') || raw.contains('password should be at least')) {
      return const AuthException('Password must be at least 8 characters.', code: 'weak_password');
    }
    if (raw.contains('network') || raw.contains('socket')) {
      return const AuthException('Network error. Check your connection and try again.', code: 'network_error');
    }
    if (raw.contains('cancel')) {
      return const AuthException('Sign-in was cancelled.', code: 'cancelled');
    }
    if (raw.contains('otp') && raw.contains('expired')) {
      return const AuthException('This code has expired. Request a new one.', code: 'otp_expired');
    }
    if (raw.contains('otp') || raw.contains('token')) {
      return const AuthException('Invalid verification code.', code: 'invalid_otp');
    }

    return const AuthException('Something went wrong. Please try again.', code: 'unknown');
  }
}
