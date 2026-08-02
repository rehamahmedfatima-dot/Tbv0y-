import 'package:dio/dio.dart';
import '../config/env_config.dart';
import 'supabase_service.dart';

/// Calls the TBVOY FastAPI backend (Phase 7) for the handful of
/// operations that must run server-side: account deletion, FCM token
/// registration, and test notifications. Every call automatically attaches
/// the current Supabase session token so the backend can verify identity.
class BackendApiClient {
  BackendApiClient._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: EnvConfig.backendApiUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  static final BackendApiClient instance = BackendApiClient._internal();
  final Dio _dio;

  Future<Options> _authOptions() async {
    final token = SupabaseService.client.auth.currentSession?.accessToken;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/account', options: await _authOptions());
  }

  Future<void> registerFcmToken(String fcmToken) async {
    await _dio.post(
      '/notifications/register-token',
      data: {'fcm_token': fcmToken},
      options: await _authOptions(),
    );
  }

  Future<void> sendTestNotification(String title, String body) async {
    await _dio.post(
      '/notifications/send-test',
      data: {'title': title, 'body': body},
      options: await _authOptions(),
    );
  }
}
