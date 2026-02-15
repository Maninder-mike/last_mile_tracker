import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/services/analytics_service.dart';
import 'core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';
import 'presentation/app.dart';
import 'core/services/config_service.dart';
import 'core/config/supabase_config.dart';
import 'core/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundServiceInstance.initialize();

  runZonedGuarded(
    () async {
      debugPrint('Init: WidgetsFlutterBinding initialized');

      await Firebase.initializeApp();
      debugPrint('Init: Firebase initialized');

      // Initialize App Check
      debugPrint('Init: Activating App Check...');
      await FirebaseAppCheck.instance.activate(
        providerApple: const AppleDebugProvider(),
        providerAndroid: const AndroidDebugProvider(),
      );
      debugPrint('Init: App Check activated');

      // Parallel initializations
      debugPrint('Init: Starting parallel initializations...');
      await Future.wait([
        FileLogger.init(),
        Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        ),
        [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request(),
      ]);
      debugPrint('Init: Parallel initializations complete');

      // Initialize Firebase services
      debugPrint('Init: Initializing secondary services...');
      final trace = FirebasePerformance.instance.newTrace('app_start_trace');
      await trace.start();

      await NotificationService().init();
      debugPrint('Init: NotificationService initialized');

      await AnalyticsService().logAppOpen();
      debugPrint('Init: Analytics logAppOpen sent');

      await ConfigService().init();
      debugPrint('Init: ConfigService initialized');

      await trace.stop();
      debugPrint('Init: All secondary services initialized');

      // Configure background message handler for FCM
      FirebaseMessaging.onBackgroundMessage(
        NotificationService.handleBackgroundMessage,
      );

      // Pass all uncaught errors from the framework to Crashlytics.
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      // 3. Full screen immersive mode
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );

      runApp(const ProviderScope(child: LastMileTrackerApp()));
    },
    (error, stack) {
      FileLogger.log("UNCAUGHT ERROR: $error\n$stack");
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
