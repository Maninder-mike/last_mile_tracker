import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/daos/sensor_dao.dart';
import '../database/app_database.dart';
import 'ble_service.dart';
import '../../core/utils/file_logger.dart';

class SyncManager {
  final SensorDao _sensorDao;
  final BleService _bleService;

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  bool _syncRequested = false;

  SyncManager(this._sensorDao, this._bleService) {
    _init();
  }

  void _init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      // Check if we have any active connection (WiFi, Mobile, etc.)
      bool isConnected = results.any((r) => r != ConnectivityResult.none);

      if (isConnected) {
        FileLogger.log("SyncManager: Connectivity restored. Resuming sync...");
        syncData();
      }
    });
  }

  static const int _batchSize = 100; // Increased for production efficiency
  int _retryDelaySeconds = 2;
  static const int _maxRetryDelaySeconds = 60;

  /// Public entry point to start synchronization.
  /// If already syncing, it flags that another sync is requested after the current one finishes.
  Future<void> syncData() async {
    _syncRequested = true;
    if (_isSyncing) return;

    await _performSyncLoop();
  }

  Future<void> _performSyncLoop() async {
    _isSyncing = true;
    _syncRequested = false;

    try {
      while (true) {
        if (!await _hasNetwork()) {
          FileLogger.log("SyncManager: No network. Pausing sync.");
          break;
        }

        // 1. Get a batch of unsynced readings
        List<SensorReading> unsynced = await _sensorDao.getUnsyncedReadings(
          _batchSize,
        );

        if (unsynced.isEmpty) {
          FileLogger.log("SyncManager: All data synced.");
          _retryDelaySeconds = 2; // Reset backoff
          break;
        }

        FileLogger.log(
          "SyncManager: Uploading batch of ${unsynced.length} readings.",
        );

        try {
          // 2. Batch upload to Supabase
          await _uploadToSupabase(unsynced);

          // 3. Mark as synced in local DB
          List<int> syncedIds = unsynced.map((e) => e.id).toList();
          await _sensorDao.markAsSynced(syncedIds);

          _retryDelaySeconds = 2; // Reset on success

          // Small delay to prevent CPU thrashing
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          FileLogger.log("SyncManager: Batch upload failed: $e");
          _scheduleRetry();
          break; // Stop loop and wait for retry
        }
      }
    } finally {
      _isSyncing = false;
      // If a new sync was requested while we were syncing, start again if we finished successfully
      if (_syncRequested) {
        _performSyncLoop();
      }
    }
  }

  Future<bool> _hasNetwork() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _uploadToSupabase(List<SensorReading> data) async {
    final client = Supabase.instance.client;
    final deviceId = _bleService.connectedDevice?.remoteId.str ?? 'dev_001';

    final payload = data.map((r) {
      return {
        'device_id': deviceId,
        'lat': r.lat,
        'lon': r.lon,
        'speed': r.speed,
        'temp': r.temp,
        'shock_value': r.shockValue,
        'battery_level': r.batteryLevel,
        'trip_state': r.tripState,
        'internal_temp': r.internalTemp,
        'additional_temps': r.additionalTemps != null ? jsonDecode(r.additionalTemps!) : null,
        'battery_drop': r.batteryDrop,
        'rssi': r.rssi,
        'reset_reason': r.resetReason,
        'uptime': r.uptime,
        'wifi_ssid': r.wifiSsid,
        'wifi_signal': r.wifiSignal,
        'timestamp': r.timestamp.toIso8601String(),
      };
    }).toList();

    await client.from('sensor_readings').insert(payload);
  }

  void _scheduleRetry() {
    FileLogger.log(
      "SyncManager: Scheduling retry in $_retryDelaySeconds seconds.",
    );

    Timer(Duration(seconds: _retryDelaySeconds), () {
      syncData();
    });

    // Exponential backoff
    _retryDelaySeconds = (_retryDelaySeconds * 2).clamp(
      2,
      _maxRetryDelaySeconds,
    );
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
