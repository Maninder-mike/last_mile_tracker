import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/sensor_dao.dart';
import '../../data/services/ble_service.dart';
import '../../data/services/sync_manager.dart';
import '../../data/services/ota_service.dart';

part 'providers.g.dart';

// Manual Ref typedefs to workaround missing generation
typedef AppDatabaseRef = Ref;
typedef SensorDaoRef = Ref;
typedef BleServiceRef = Ref;
typedef BleConnectionStateRef = Ref;
typedef SyncManagerRef = Ref;
typedef OtaServiceRef = Ref;
typedef LatestReadingRef = Ref;
typedef RecentReadingsRef = Ref;
typedef RecentPathRef = Ref;

// Database
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  return AppDatabase();
}

// DAO
@Riverpod(keepAlive: true)
SensorDao sensorDao(SensorDaoRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.sensorDao;
}

@Riverpod(keepAlive: true)
BleService bleService(BleServiceRef ref) {
  final dao = ref.watch(sensorDaoProvider);
  final service = BleService(dao);
  service.startScanning(); // Auto-start scanning on app launch
  ref.onDispose(() => service.dispose());
  return service;
}

// BLE Connection State Provider
@riverpod
Stream<BluetoothConnectionState> bleConnectionState(BleConnectionStateRef ref) {
  final service = ref.watch(bleServiceProvider);
  return service.connectionState;
}

// ...

// Sync Manager
@Riverpod(keepAlive: true)
SyncManager syncManager(SyncManagerRef ref) {
  final dao = ref.watch(sensorDaoProvider);
  return SyncManager(dao);
}

// OTA Service
@Riverpod(keepAlive: true)
OtaService otaService(OtaServiceRef ref) {
  final service = OtaService();
  ref.onDispose(() => service.dispose());
  return service;
}

// Stream of latest sensor reading for Dashboard
@riverpod
Stream<dynamic> latestReading(LatestReadingRef ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchLatestReading();
}

// Stream of recent readings for Logs
@riverpod
Stream<List<dynamic>> recentReadings(RecentReadingsRef ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchLatestReadings();
}

// Stream of recent path for Map
@riverpod
Stream<List<dynamic>> recentPath(RecentPathRef ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchRecentPath();
}
