import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/presentation/app.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/shipments_page.dart';
import 'package:last_mile_tracker/presentation/pages/devices/device_detail_page.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Service to handle both Remote (FCM) and Local notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Channels
  static const String _criticalChannelId = 'critical_alerts';
  static const String _infoChannelId = 'info_alerts';

  /// Initializes notification handling.
  Future<void> init() async {
    // 1. Initialize Local Notifications
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android Notification Channels
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _criticalChannelId,
          'Critical Alerts',
          description: 'Last Mile Tracker critical shipment alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _infoChannelId,
          'Information',
          description: 'Last Mile Tracker shipment updates',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );
    }

    // 2. Request FCM Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification: Permissions granted');
    }

    // 3. Get FCM Token
    try {
      String? token = await _fcm.getToken();
      debugPrint('Notification: FCM Token: $token');
    } catch (e) {
      debugPrint('Notification: Error getting FCM token: $e');
    }

    // 4. Configure Foreground Handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle app opened via notification (FCM running/background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'Notification: App opened via FCM: ${message.notification?.title}',
      );
      _handleNavigationFromMessage(message.data);
    });

    // 6. Handle cold start from terminated state (FCM)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        'Notification: Cold start from FCM: ${initialMessage.notification?.title}',
      );
      Future.delayed(const Duration(milliseconds: 1000), () {
        _handleNavigationFromMessage(initialMessage.data);
      });
    }

    // 7. Handle cold start from terminated state (Local)
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null) {
        debugPrint('Notification: Cold start from Local payload: $payload');
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleNavigationFromMessage({'type': payload});
        });
      }
    }
  }

  void _handleNavigationFromMessage(Map<String, dynamic> data) {
    if (data.containsKey('type')) {
      final type = data['type'] as String;
      final navContext = navigatorKey.currentState?.context;
      if (navContext != null) {
        if (type == 'new_shipment' || type == 'shipment_update') {
          Navigator.of(
            navContext,
          ).push(CupertinoPageRoute(builder: (_) => const ShipmentsPage()));
        } else if (type.startsWith('alert_')) {
          final deviceId = type.replaceFirst('alert_', '');
          Navigator.of(navContext).push(
            CupertinoPageRoute(
              builder: (_) => DeviceDetailPage(
                deviceId: deviceId,
                name: 'Device $deviceId',
              ),
            ),
          );
        }
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification: Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      _handleNavigationFromMessage({'type': response.payload});
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      'Notification: Received FCM foreground: ${message.notification?.title}',
    );

    // Explicitly show local notification for foreground FCM messages
    final notification = message.notification;
    if (notification != null) {
      await showNotification(
        title: notification.title ?? 'Update',
        body: notification.body ?? '',
        payload: message.data['type'] ?? 'fcm_message',
      );
    }
  }

  /// Shows a local notification banner.
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool isCritical = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      isCritical ? _criticalChannelId : _infoChannelId,
      isCritical ? 'Critical Alerts' : 'Information',
      channelDescription: 'Last Mile Tracker shipment alerts',
      importance: isCritical ? Importance.max : Importance.defaultImportance,
      priority: isCritical ? Priority.high : Priority.defaultPriority,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Notification: Handling background FCM: ${message.messageId}');
  }
}
