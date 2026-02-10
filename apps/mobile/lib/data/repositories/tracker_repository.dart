import 'dart:convert';
import 'package:drift/drift.dart';
import '../../data/services/ble/scanned_tracker.dart';
import '../../data/services/ble_service.dart';
import '../database/app_database.dart';
import '../database/daos/tracker_dao.dart';

class TrackerRepository {
  final BleService _bleService;
  final TrackerDao _trackerDao;

  TrackerRepository(this._bleService, this._trackerDao);

  void startSync() {
    _bleService.discoveredDevices.listen((scannedTrackers) {
      for (final scanned in scannedTrackers) {
        _persistTracker(scanned);
      }
    });
  }

  Future<void> _persistTracker(ScannedTracker scanned) async {
    final companion = TrackersCompanion(
      id: Value(scanned.device.remoteId.str),
      name: Value(scanned.device.platformName),
      lastSeen: Value(scanned.lastSeen),
      // rssi: Value(scanned.rssi), // Not in schema yet
      batteryLevel: Value(scanned.telemetry?.batteryLevel ?? 0.0),
      temp: Value(scanned.telemetry?.temp ?? 0.0),
      shockValue: Value(scanned.telemetry?.shockValue ?? 0),
      additionalTemps: Value(
        scanned.telemetry?.additionalTemps != null &&
                scanned.telemetry!.additionalTemps.isNotEmpty
            ? jsonEncode(scanned.telemetry!.additionalTemps)
            : null,
      ),
      batteryDrop: Value(scanned.telemetry?.batteryDrop),
      status: const Value('active'), // Default status
    );

    await _trackerDao.upsertTracker(companion);
  }

  Stream<List<Tracker>> watchAllTrackers() {
    return _trackerDao.watchAllTrackers();
  }
}
