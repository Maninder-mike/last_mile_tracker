import 'dart:async';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/alert_dao.dart';
import '../data/services/ble_service.dart';
import '../data/services/ble/scanned_tracker.dart';
import '../presentation/providers/database_providers.dart';
import '../presentation/providers/ble_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';

final alertManagerProvider = Provider<AlertManager>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  final alertDao = ref.watch(alertDaoProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final manager = AlertManager(bleService, alertDao, notificationService);
  manager.startMonitoring();
  return manager;
});

class AlertManager {
  final BleService _bleService;
  final AlertDao _alertDao;
  final NotificationService _notificationService;

  // Configuration
  static const double batteryThreshold = 20.0;
  static const double tempThreshold = 40.0;
  static const double shockThreshold = 0.5; // G-force threshold

  // Simple in-memory debounce to avoid spamming alerts
  final Map<String, DateTime> _lastAlertTime = {};
  static const _debounceDuration = Duration(minutes: 10);

  AlertManager(this._bleService, this._alertDao, this._notificationService);

  void startMonitoring() {
    _bleService.discoveredDevices.listen((trackers) {
      for (final tracker in trackers) {
        _checkTracker(tracker);
      }
    });
  }

  /// Public API to create an alert from external services (e.g. ProximityService)
  Future<void> createAlert({
    required String title,
    required String message,
    required String type,
    required String trackerId,
  }) async {
    await _triggerAlert(trackerId, title, message, type);
  }

  Future<void> _checkTracker(ScannedTracker tracker) async {
    final telemetry = tracker.telemetry;
    if (telemetry == null) return;

    final deviceId = tracker.device.remoteId.str;
    final deviceName = tracker.device.platformName.isEmpty
        ? 'Tracker ${deviceId.substring(0, 4)}'
        : tracker.device.platformName;

    // Check Battery
    if (telemetry.batteryLevel < batteryThreshold) {
      await _triggerAlert(
        deviceId,
        'Low Battery',
        '$deviceName battery is critical (${telemetry.batteryLevel.toInt()}%)',
        'critical',
      );
    }

    // Check Temp
    if (telemetry.temp > tempThreshold) {
      await _triggerAlert(
        deviceId,
        'High Temperature',
        '$deviceName temperature exceeds threshold (${telemetry.temp.toStringAsFixed(1)}°C)',
        'warning',
      );
    }

    // Check Shock
    if (telemetry.shockValue > shockThreshold) {
      await _triggerAlert(
        deviceId,
        'Shock Detected',
        '$deviceName experienced a significant impact.',
        'critical',
      );
    }
  }

  Future<void> _triggerAlert(
    String deviceId,
    String title,
    String message,
    String type,
  ) async {
    final key = '$deviceId-$title';
    final now = DateTime.now();

    // Debounce check
    if (_lastAlertTime.containsKey(key)) {
      final last = _lastAlertTime[key]!;
      if (now.difference(last) < _debounceDuration) {
        return;
      }
    }

    _lastAlertTime[key] = now;

    await _alertDao.insertAlert(
      AlertsCompanion(
        title: Value(title),
        message: Value(message),
        type: Value(type),
        trackerId: Value(deviceId),
        timestamp: Value(now),
        isRead: const Value(false),
      ),
    );

    // Show visual banner via NotificationService
    await _notificationService.showNotification(
      title: title,
      body: message,
      isCritical: type == 'critical',
      payload: 'alert_$deviceId',
    );
  }
}
