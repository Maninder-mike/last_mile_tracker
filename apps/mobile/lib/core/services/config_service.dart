import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 12),
        ),
      );

      // Set default values here
      await _remoteConfig.setDefaults({
        'maintenance_mode': false,
        'backend_url': 'https://api.lastmiletracker.com',
      });

      await fetchAndActivate();
      debugPrint('Remote Config: Initialized');
    } catch (e) {
      debugPrint('Remote Config: Failed to initialize: $e');
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      bool updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        debugPrint('Remote Config: Fetched and activated new values');
      }
    } catch (e) {
      debugPrint('Remote Config: Failed to fetch and activate: $e');
    }
  }

  bool get maintenanceMode => _remoteConfig.getBool('maintenance_mode');
  String get backendUrl => _remoteConfig.getString('backend_url');
}
