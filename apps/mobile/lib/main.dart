import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/services/analytics_service.dart';
import 'logic/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';
import 'presentation/app.dart';
import 'core/services/config_service.dart';
import 'core/services/app_link_service.dart';
import 'core/config/supabase_config.dart';
import 'core/services/background_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('Init: WidgetsFlutterBinding initialized');

      await SentryFlutter.init((options) {
        options.dsn = const String.fromEnvironment('SENTRY_DSN');
        options.tracesSampleRate = 1.0;
      });
      debugPrint('Init: Sentry initialized');

      await Firebase.initializeApp();
      debugPrint('Init: Firebase initialized');

      await BackgroundServiceInstance.initialize();
      debugPrint('Init: Background Service initialized');

      // Initialize App Check
      debugPrint('Init: Activating App Check...');
      await FirebaseAppCheck.instance.activate(
        providerApple: kReleaseMode
            ? AppleAppAttestProvider()
            : const AppleDebugProvider(),
        providerAndroid: kReleaseMode
            ? AndroidPlayIntegrityProvider()
            : const AndroidDebugProvider(),
      );
      debugPrint('Init: App Check activated');

      final isPlaceholder = SupabaseConfig.url.isEmpty ||
          SupabaseConfig.url == 'https://your-project.supabase.co' ||
          SupabaseConfig.anonKey.isEmpty;

      // Parallel initializations
      debugPrint('Init: Starting parallel initializations...');
      await Future.wait([
        FileLogger.init(),
        if (!isPlaceholder)
          Supabase.initialize(
            url: SupabaseConfig.url,
            publishableKey: SupabaseConfig.anonKey,
          )
        else
          Future.value(null),
        [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
          Permission.notification,
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

      await AppLinkService().init();
      debugPrint('Init: AppLinkService initialized');

      await trace.stop();
      debugPrint('Init: All secondary services initialized');

      // Configure background message handler for FCM
      FirebaseMessaging.onBackgroundMessage(
        NotificationService.handleBackgroundMessage,
      );

      // Pass all uncaught errors from the framework to Crashlytics and Sentry.
      FlutterError.onError = (details) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
        Sentry.captureException(details.exception, stackTrace: details.stack);
      };

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
      Sentry.captureException(error, stackTrace: stack);
    },
  );
}
