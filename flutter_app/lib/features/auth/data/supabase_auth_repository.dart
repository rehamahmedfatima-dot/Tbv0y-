import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/network/backend_api_client.dart';
import '../../../core/network/supabase_service.dart';
import 'app_user.dart';
import 'auth_exceptions.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final sb.SupabaseClient _client = SupabaseService.client;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _biometricEnabledKey = 'biometric_enabled';

  AppUser? _mapUser(sb.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email,
      displayName: (user.userMetadata?['full_name'] ?? user.userMetadata?['name']) as String?,
      photoUrl: user.userMetadata?['avatar_url'] as String?,
      isAnonymous: user.isAnonymous,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((state) => _mapUser(state.session?.user));

  @override
  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  // ---------------------------------------------------------------------
  // Google — native sign-in, token handed to Supabase for verification.
  // ---------------------------------------------------------------------
  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        // Required for Supabase to verify the ID token server-side.
        serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Sign-in was cancelled.', code: 'cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AuthException('Google sign-in failed to return a token.', code: 'no_token');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = _mapUser(response.user);
      if (user == null) throw const AuthException('Google sign-in failed.', code: 'unknown');
      return user;
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  // ---------------------------------------------------------------------
  // Apple — native sign-in with nonce, iOS only.
  // ---------------------------------------------------------------------
  @override
  Future<AppUser> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple sign-in failed to return a token.', code: 'no_token');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final user = _mapUser(response.user);
      if (user == null) throw const AuthException('Apple sign-in failed.', code: 'unknown');
      return user;
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // ---------------------------------------------------------------------
  // Anonymous guest mode
  // ---------------------------------------------------------------------
  @override
  Future<AppUser> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();
      final user = _mapUser(response.user);
      if (user == null) throw const AuthException('Guest sign-in failed.', code: 'unknown');
      return user;
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  // ---------------------------------------------------------------------
  // Email & password
  // ---------------------------------------------------------------------
  @override
  Future<AppUser> signUpWithEmail({required String email, required String password}) async {
    try {
      final response = await _client.auth.signUp(email: email, password: password);
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthException(
          'Account created — check your email to confirm before signing in.',
          code: 'confirmation_required',
        );
      }
      return user;
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(email: email, password: password);
      final user = _mapUser(response.user);
      if (user == null) throw const AuthException('Sign-in failed.', code: 'unknown');
      return user;
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  // ---------------------------------------------------------------------
  // OTP verification (used for email confirmation / passwordless flows)
  // ---------------------------------------------------------------------
  @override
  Future<void> sendOtp(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email);
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  @override
  Future<void> verifyOtp({required String email, required String token}) async {
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: sb.OtpType.email,
      );
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  // ---------------------------------------------------------------------
  // Biometric unlock (device-level — gates access to an existing session)
  // ---------------------------------------------------------------------
  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to open TBVOY',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on Exception {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());

  Future<bool> getBiometricEnabled() async =>
      (await _secureStorage.read(key: _biometricEnabledKey)) == 'true';

  // ---------------------------------------------------------------------
  @override
  Future<void> signOut() async {
    try {
      final isMobile = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
      if (!isMobile) {
        await _client.auth.signOut();
        return;
      }
      await GoogleSignIn().signOut().catchError((_) {});
      await _client.auth.signOut();
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    // Account deletion needs the service_role key and must run
    // server-side — the FastAPI backend's DELETE /account endpoint
    // (see backend/app/api/routes/account.py) does this, never the client.
    try {
      await BackendApiClient.instance.deleteAccount();
      await signOut();
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }
}
