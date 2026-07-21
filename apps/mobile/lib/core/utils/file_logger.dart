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
    // 1. Sanitize coordinates for privacy in logs
    String sanitized = message.replaceAllMapped(
      RegExp(r'(lat|lon):\s*(-?\d+\.\d{2})\d+'),
      (match) => "${match.group(1)}: ${match.group(2)}***",
    );

    // 2. Redact JWT tokens (eyJ...)
    sanitized = sanitized.replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
      '[REDACTED_JWT_TOKEN]',
    );

    // 3. Redact Bearer Authorization headers
    sanitized = sanitized.replaceAll(
      RegExp(r'Bearer\s+[^\s\n]+', caseSensitive: false),
      'Bearer [REDACTED]',
    );

    // 4. Redact API keys, secrets, and passwords
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(anonKey|apiKey|password|secret|anon_key)=\s*([^\s,;&]+)', caseSensitive: false),
      (match) => "${match.group(1)}=[REDACTED]",
    );

    final timestamp = DateTime.now().toIso8601String();
    final entry = "[$timestamp] $sanitized\n";

    // Always print to console (un-sanitized for dev if needed, but let's be safe)
    debugPrint(entry.trim());

    // Write to file if available and rotate if size > 2MB
    if (_logFile != null) {
      try {
        if (_logFile!.existsSync() &&
            _logFile!.lengthSync() > 2 * 1024 * 1024) {
          final oldFile = File('${_logFile!.path}.old');
          if (oldFile.existsSync()) {
            oldFile.deleteSync();
          }
          _logFile!.renameSync(oldFile.path);
        }
        _logFile!.writeAsStringSync(entry, mode: FileMode.append);
      } catch (e) {
        debugPrint("FileLogger: Write error: $e");
      }
    }
  }

  static Future<String> getLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return "No logs found.";
  }
}
