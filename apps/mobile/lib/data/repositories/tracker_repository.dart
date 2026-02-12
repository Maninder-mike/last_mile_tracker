import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/services/ble/scanned_tracker.dart';
import '../../data/services/ble_service.dart';
import '../database/app_database.dart';
import '../database/daos/tracker_dao.dart';
import 'package:lmt_models/lmt_models.dart' as models;

class TrackerRepository {
  final BleService _bleService;
  final TrackerDao _trackerDao;

  TrackerRepository(this._bleService, this._trackerDao);

  void startSync() {
    // 1. Listen to advertisement data (broadcast readings)
    _bleService.discoveredDevices.listen((scannedTrackers) {
      for (final scanned in scannedTrackers) {
        _persistTracker(scanned);
      }
    });

    // 2. Listen to live connection data (notifications)
    _bleService.liveTelemetry.listen((reading) {
      final device = _bleService.connectedDevice;
      if (device != null) {
        _persistLiveReading(device, reading);
      }
    });
  }

  Future<void> _persistLiveReading(
    BluetoothDevice device,
    models.SensorReading reading,
  ) async {
    // Distinguish between V1 (Primary) and V2 (Auxiliary) payloads
    // V1 always contains battery level (non-zero) and primary sensors
    // V2 is focused on multi-temp and health metrics
    final bool isV1 = reading.batteryLevel != 0;
    final bool isV2 =
        reading.additionalTemps.isNotEmpty ||
        (reading.batteryDrop != null && reading.batteryDrop != 0);

    final companion = TrackersCompanion(
      id: Value(device.remoteId.str),
      name: Value(device.platformName),
      lastSeen: Value(reading.timestamp),
      status: const Value('active'),

      // V1 Primary Fields
      batteryLevel: isV1 ? Value(reading.batteryLevel) : const Value.absent(),
      temp: isV1 ? Value(reading.temp) : const Value.absent(),
      shockValue: isV1 ? Value(reading.shockValue) : const Value.absent(),
      lat: isV1 ? Value(reading.lat) : const Value.absent(),
      lon: isV1 ? Value(reading.lon) : const Value.absent(),

      // V2 Auxiliary Fields
      additionalTemps: isV2
          ? Value(
              reading.additionalTemps.isNotEmpty
                  ? jsonEncode(reading.additionalTemps)
                  : null,
            )
          : const Value.absent(),
      batteryDrop: isV2 ? Value(reading.batteryDrop) : const Value.absent(),
      isFavorite:
          const Value.absent(), // Don't overwrite favorite status on sync
    );

    await _trackerDao.upsertTracker(companion);
  }

  Future<void> _persistTracker(ScannedTracker scanned) async {
    final companion = TrackersCompanion(
      id: Value(scanned.device.remoteId.str),
      name: Value(scanned.device.platformName),
      lastSeen: Value(scanned.lastSeen),
      // rssi: Value(scanned.rssi), // Not in schema yet
      batteryLevel: Value(scanned.telemetry?.batteryLevel),
      temp: Value(scanned.telemetry?.temp),
      shockValue: Value(scanned.telemetry?.shockValue),
      additionalTemps: Value(
        scanned.telemetry?.additionalTemps != null &&
                scanned.telemetry!.additionalTemps.isNotEmpty
            ? jsonEncode(scanned.telemetry!.additionalTemps)
            : null,
      ),
      batteryDrop: Value(scanned.telemetry?.batteryDrop),
      status: const Value('active'), // Default status
      lat: Value(scanned.telemetry?.lat),
      lon: Value(scanned.telemetry?.lon),
      isFavorite:
          const Value.absent(), // Don't overwrite favorite status on scan
    );

    await _trackerDao.upsertTracker(companion);
  }

  Stream<List<Tracker>> watchAllTrackers() {
    return _trackerDao.watchAllTrackers();
  }

  Stream<Tracker?> watchTracker(String id) {
    return _trackerDao.watchTracker(id);
  }

  Future<void> updateFavorite(String id, bool isFavorite) async {
    await _trackerDao.updateFavorite(id, isFavorite);
  }

  Stream<List<Tracker>> watchFavorites() {
    return _trackerDao.watchFavorites();
  }
}
