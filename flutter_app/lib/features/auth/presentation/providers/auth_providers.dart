import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Emits the current user whenever auth state changes — screens/router
/// listen to this to decide between splash / onboarding / login / home.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

enum AuthStatus { idle, loading, error }

class AuthController extends StateNotifier<AuthStatus> {
  AuthController(this._repo) : super(AuthStatus.idle);
  final AuthRepository _repo;
  String? errorMessage;

  Future<bool> _run(Future<void> Function() action) async {
    state = AuthStatus.loading;
    errorMessage = null;
    try {
      await action();
      state = AuthStatus.idle;
      return true;
    } catch (e) {
      errorMessage = e.toString();
      state = AuthStatus.error;
      return false;
    }
  }

  Future<bool> signInWithGoogle() => _run(() => _repo.signInWithGoogle());
  Future<bool> signInWithApple() => _run(() => _repo.signInWithApple());
  Future<bool> signInAnonymously() => _run(() => _repo.signInAnonymously());

  Future<bool> signInWithEmail(String email, String password) =>
      _run(() => _repo.signInWithEmail(email: email, password: password));

  Future<bool> signUpWithEmail(String email, String password) =>
      _run(() => _repo.signUpWithEmail(email: email, password: password));

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordResetEmail(email));

  Future<bool> sendOtp(String email) => _run(() => _repo.sendOtp(email));

  Future<bool> verifyOtp(String email, String token) =>
      _run(() => _repo.verifyOtp(email: email, token: token));

  Future<bool> signOut() => _run(() => _repo.signOut());
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthStatus>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
