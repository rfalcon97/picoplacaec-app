import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'notification_history_service.dart';
import 'screens/notification_history_screen.dart' show unreadNotificationCountProvider;

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

/// Watch this from `HomeScreen` (or anywhere reached only while logged in)
/// to register/refresh this device's push token exactly once per session.
final pushInitProvider = FutureProvider<void>((ref) {
  return ref.watch(pushNotificationServiceProvider).init();
});

/// Real server-triggered push, on top of the on-device reminders in
/// [NotificationService]. Registers this device's FCM token with the
/// backend whenever a session starts, and displays a local notification
/// when a push arrives while the app is in the foreground (Android doesn't
/// show those automatically, unlike background/terminated pushes).
class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  final _localPlugin = FlutterLocalNotificationsPlugin();
  final _historyService = NotificationHistoryService();
  bool _listening = false;

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission();

    if (!_listening) {
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_recordMessage);
      FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) await _recordMessage(initialMessage);
      _listening = true;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerToken(token);
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.dio.post('/notifications/register-token', data: {'token': token, 'platform': 'android'});
    } catch (_) {
      // Not logged in yet, or offline — harmless, we retry on the next init().
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localPlugin.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'server_push',
          'Avisos importantes',
          channelDescription: 'Alertas urgentes enviadas por el equipo de Pico y Placa EC',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
    await _recordMessage(message);
  }

  Future<void> _recordMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification?.title == null || notification?.body == null) return;
    await _historyService.recordPush(title: notification!.title!, body: notification.body!);
    _ref.invalidate(unreadNotificationCountProvider);
  }
}
