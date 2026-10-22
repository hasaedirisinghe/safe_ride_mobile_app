import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _local = FlutterLocalNotificationsPlugin();
  final ValueNotifier<String?> tappedPayload = ValueNotifier(null);
  bool configured = false;

  Future<void> initialize() async {
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) =>
            tappedPayload.value = response.payload,
      );
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => tappedPayload.value =
            message.data['route']?.toString() ?? '/notifications',
      );
      configured = true;
    } catch (_) {
      // Demo Mode and unconfigured builds intentionally continue without Firebase.
      configured = false;
    }
  }

  Future<void> _showForeground(RemoteMessage message) => _local.show(
    id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    title: message.notification?.title ?? 'SafeRide-LK update',
    body: message.notification?.body,
    payload: message.data['route']?.toString() ?? '/notifications',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'transport_updates',
        'Transport updates',
        channelDescription: 'Boarding, arrival, safety, and trip updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );

  Future<String?> requestToken() async {
    if (!configured) return null;
    await FirebaseMessaging.instance.requestPermission();
    return FirebaseMessaging.instance.getToken();
  }

  Stream<String> get tokenRefresh => configured
      ? FirebaseMessaging.instance.onTokenRefresh
      : const Stream<String>.empty();
}
