import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/backend_api_client.dart';

/// Wires up Firebase Cloud Messaging: asks for permission, registers the
/// device token with the FastAPI backend (so scheduled jobs can reach this
/// device), and shows foreground pushes as local notifications since FCM
/// doesn't auto-display those while the app is open.
class PushNotificationService {
  PushNotificationService._();
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await BackendApiClient.instance.registerFcmToken(token);
    }
    _messaging.onTokenRefresh.listen((newToken) {
      BackendApiClient.instance.registerFcmToken(newToken);
    });

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'tbvoy_default',
      'TBVOY Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _local.show(
      message.hashCode,
      message.notification?.title ?? 'TBVOY',
      message.notification?.body ?? '',
      details,
    );
  }
}
