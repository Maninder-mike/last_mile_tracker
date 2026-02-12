import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/app.dart';
import 'core/utils/file_logger.dart';
import 'core/config/supabase_config.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Parallel initializations
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
      // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
