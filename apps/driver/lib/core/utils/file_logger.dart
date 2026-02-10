import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class FileLogger {
  static File? _logFile;

  static Future<void> init() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        _logFile = File('${dir.path}/app_logs.txt');
        if (!await _logFile!.exists()) {
          await _logFile!.create();
        }
        log("Logger Initialized");
      }
    } catch (e) {
      debugPrint("Logger Init Error: $e");
    }
  }

  static void log(String message) {
    // Sanitize coordinates for privacy in logs
    // Example: "lat: 45.12345, lon: -75.12345" -> "lat: 45.12***, lon: -75.12***"
    String sanitized = message.replaceAllMapped(
      RegExp(r'(lat|lon):\s*(-?\d+\.\d{2})\d+'),
      (match) => "${match.group(1)}: ${match.group(2)}***",
    );

    final timestamp = DateTime.now().toIso8601String();
    final entry = "[$timestamp] $sanitized\n";

    // Always print to console (un-sanitized for dev if needed, but let's be safe)
    debugPrint(entry.trim());

    // Write to file if available
    _logFile?.writeAsStringSync(entry, mode: FileMode.append);
  }

  static Future<String> getLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return "No logs found.";
  }
}
