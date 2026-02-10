import 'dart:async';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/alert_dao.dart';
import '../data/services/ble_service.dart';
import '../data/services/ble/scanned_tracker.dart';

class AlertManager {
  final BleService _bleService;
  final AlertDao _alertDao;

  // Simple in-memory debounce to avoid spamming alerts for the same condition
  final Map<String, DateTime> _lastAlertTime = {};
  static const _debounceDuration = Duration(minutes: 5);

  AlertManager(this._bleService, this._alertDao);

  void startMonitoring() {
    _bleService.discoveredDevices.listen((trackers) {
      for (final tracker in trackers) {
        _checkTracker(tracker);
      }
    });
  }

  Future<void> _checkTracker(ScannedTracker tracker) async {
    final telemetry = tracker.telemetry;
    if (telemetry == null) return;

    final deviceId = tracker.device.remoteId.str;
    final deviceName = tracker.device.platformName.isEmpty
        ? 'Unknown Device'
        : tracker.device.platformName;

    // Check Battery
    if (telemetry.batteryLevel < 20) {
      await _triggerAlert(
        deviceId,
        'Low Battery',
        '$deviceName battery is critical (${telemetry.batteryLevel.toInt()}%)',
        'critical',
      );
    }

    // Check Temp
    if (telemetry.temp > 40) {
      // Threshold 40C
      await _triggerAlert(
        deviceId,
        'High Temperature',
        '$deviceName temperature is high (${telemetry.temp.toStringAsFixed(1)}°C)',
        'warning',
      );
    }

    // Check Shock
    if (telemetry.shockValue > 0) {
      await _triggerAlert(
        deviceId,
        'Shock Detected',
        '$deviceName experienced a shock event.',
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

    if (_lastAlertTime.containsKey(key)) {
      final last = _lastAlertTime[key]!;
      if (now.difference(last) < _debounceDuration) {
        return; // Debounced
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
  }
}
