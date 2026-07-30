import 'app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<AppUser> signInAnonymously();

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> verifyOtp({
    required String email,
    required String token,
  });

  Future<void> sendOtp(String email);

  Future<bool> isBiometricAvailable();
  Future<bool> authenticateWithBiometrics();

  Future<void> signOut();
  Future<void> deleteAccount();
}
