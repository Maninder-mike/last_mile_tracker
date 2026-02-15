import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';
import 'package:last_mile_tracker/data/database/app_database.dart';
import 'package:last_mile_tracker/data/services/ble_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

@pragma('vm:entry-point')
class BackgroundServiceInstance {
  static const String channelId = 'ble_foreground_service';
  static const int notificationId = 888;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    /// OPTIONAL: register for termination listener
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      'BLE Background Service',
      description: 'This channel is used for BLE background service.',
      importance: Importance.low, // low importance so it doesn't vibrate
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true, // Start automatically on app launch
        isForegroundMode: true,
        notificationChannelId: channelId,
        initialNotificationTitle: 'Last Mile Tracker',
        initialNotificationContent: 'Searching for devices...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // 1. Initialize Database & DAO for background isolate
    final db = AppDatabase();
    final sensorDao = db.sensorDao;

    // 2. Initialize BLE Service
    final bleService = BleService(sensorDao);

    service.on('stopService').listen((event) {
      bleService.dispose();
      db.close();
      service.stopSelf();
    });

    // Handle background logic - Auto-connect and log
    bleService.startScanning();
    FileLogger.log('Background Service: BLE Scanning started');

    service.on('startScan').listen((event) {
      bleService.startScanning();
    });

    service.on('stopScan').listen((event) {
      // Manual stop if needed
    });

    // Update notification with status
    bleService.connectionState.listen((state) {
      String status = "Searching...";
      if (state == BluetoothConnectionState.connected) {
        status =
            "Connected to ${bleService.connectedDevice?.platformName ?? 'Device'}";
      }

      flutterLocalNotificationsPlugin.show(
        notificationId,
        'Last Mile Tracker (Active)',
        status,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'BLE Background Service',
            icon: 'ic_bg_service_small',
            ongoing: true,
            importance: Importance.low,
          ),
        ),
      );
    });

    // Logging heartbeat
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      FileLogger.log(
        'Background Service: Status: ${bleService.lastState}, IsScanning: ${bleService.isScanning}',
      );
    });
  }
}
