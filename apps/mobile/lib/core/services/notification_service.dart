import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Firebase Cloud Messaging.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Initializes notification handling.
  Future<void> init() async {
    // Request permissions for iOS and Android
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    } else {
      debugPrint('User declined or has not accepted notification permissions');
    }

    // Get the FCM token for this device
    String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'FCM: Received foreground message: ${message.notification?.title}',
      );
      // Here you can trigger local notifications or update UI state
    });

    // Handle background/terminated messages when app is opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'FCM: App opened via notification: ${message.notification?.title}',
      );
    });
  }

  /// Sets up background message handler.
  /// Must be a top-level function.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('FCM: Handling background message: ${message.messageId}');
  }
}
