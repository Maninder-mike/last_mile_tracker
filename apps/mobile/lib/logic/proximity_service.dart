import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/data/services/ble/scanned_tracker.dart';
import 'package:last_mile_tracker/logic/alert_manager.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final proximityServiceProvider = Provider((ref) => ProximityService(ref));

class ProximityService {
  final Ref _ref;
  final Map<String, DateTime> _lastSeen = {};
  final Set<String> _currentlyInRange = {};

  // Thresholds
  static const Duration outOfRangeThreshold = Duration(seconds: 30);
  static const int rssiThreshold = -85; // dBm

  ProximityService(this._ref) {
    _init();
  }

  void _init() {
    // Listen to BLE scan results
    _ref.listen(bleScanResultsProvider, (previous, next) {
      next.whenData(_processScanResults);
    });

    // Cleanup timer for "Out of Range" events
    Timer.periodic(const Duration(seconds: 10), (_) => _checkTimeouts());
  }

  void _processScanResults(List<ScannedTracker> results) {
    for (final tracker in results) {
      final id = tracker.id;
      final rssi = tracker.rssi;

      _lastSeen[id] = DateTime.now();

      if (rssi > rssiThreshold) {
        if (!_currentlyInRange.contains(id)) {
          _onEnterRange(tracker);
        }
      }
    }
  }

  void _checkTimeouts() {
    final now = DateTime.now();
    final toRemove = <String>[];

    for (final id in _currentlyInRange) {
      final lastSeen = _lastSeen[id];
      if (lastSeen == null || now.difference(lastSeen) > outOfRangeThreshold) {
        toRemove.add(id);
      }
    }

    for (final id in toRemove) {
      _onExitRange(id);
    }
  }

  void _onEnterRange(ScannedTracker tracker) {
    _currentlyInRange.add(tracker.id);
    _notify('Tracker Nearby', '${tracker.name} is now in range.', tracker.id);
  }

  void _onExitRange(String deviceId) {
    _currentlyInRange.remove(deviceId);
    _notify(
      'Tracker Out of Range',
      'Device $deviceId has left the immediate vicinity.',
      deviceId,
    );
  }

  Future<void> _notify(String title, String body, String deviceId) async {
    // Integrate with AlertManager for persistence
    _ref
        .read(alertManagerProvider)
        .createAlert(
          title: title,
          message: body,
          type: 'proximity',
          trackerId: deviceId,
        );

    // Trigger system notification
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      'proximity_alerts',
      'Proximity Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      deviceId.hashCode,
      title,
      body,
      details,
    );
  }
}
