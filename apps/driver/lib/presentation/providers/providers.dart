import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/sensor_dao.dart';
import '../../data/services/ble_service.dart';
import '../../data/services/sync_manager.dart';
import '../../data/services/ota_service.dart';

part 'providers.g.dart';

// Database
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}

// DAO
@Riverpod(keepAlive: true)
SensorDao sensorDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.sensorDao;
}

@Riverpod(keepAlive: true)
BleService bleService(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  final service = BleService(dao);
  service.startScanning(); // Auto-start scanning on app launch
  ref.onDispose(() => service.dispose());
  return service;
}

// BLE Connection State Provider
@riverpod
Stream<BluetoothConnectionState> bleConnectionState(Ref ref) {
  final service = ref.watch(bleServiceProvider);
  return service.connectionState;
}

// ...

// Sync Manager
@Riverpod(keepAlive: true)
SyncManager syncManager(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  return SyncManager(dao);
}

// OTA Service
@Riverpod(keepAlive: true)
OtaService otaService(Ref ref) {
  final service = OtaService();
  ref.onDispose(() => service.dispose());
  return service;
}

// Stream of latest sensor reading for Dashboard
@riverpod
Stream<SensorReading?> latestReading(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchLatestReading();
}

// Stream of recent readings for Logs
@riverpod
Stream<List<SensorReading>> recentReadings(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchLatestReadings();
}

// Stream of recent path for Map
@riverpod
Stream<List<SensorReading>> recentPath(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchRecentPath();
}
