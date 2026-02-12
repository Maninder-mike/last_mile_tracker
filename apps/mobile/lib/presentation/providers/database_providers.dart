import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:last_mile_tracker/data/database/app_database.dart';
import 'package:last_mile_tracker/data/database/daos/sensor_dao.dart';
import 'package:last_mile_tracker/data/database/daos/tracker_dao.dart';
import 'package:last_mile_tracker/data/database/daos/alert_dao.dart';
import 'package:lmt_models/lmt_models.dart' as models;

part 'database_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}

@Riverpod(keepAlive: true)
SensorDao sensorDao(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.sensorDao;
}

@Riverpod(keepAlive: true)
TrackerDao trackerDao(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.trackerDao;
}

@Riverpod(keepAlive: true)
AlertDao alertDao(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.alertDao;
}

@riverpod
Stream tracker(Ref ref, String id) {
  final dao = ref.watch(trackerDaoProvider);
  return dao.watchTracker(id);
}

@riverpod
Stream<models.SensorReading?> latestReading(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchLatestReading().map((r) => r?.toModel());
}

@riverpod
Stream<List<models.SensorReading>> recentReadings(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchLatestReadings().map(
    (list) => list.map((r) => r.toModel()).toList(),
  );
}

@riverpod
Stream<List<models.SensorReading>> recentPath(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchRecentPath().map(
    (list) => list.map((r) => r.toModel()).toList(),
  );
}

extension on SensorReading {
  models.SensorReading toModel() {
    return models.SensorReading(
      id: id,
      timestamp: timestamp,
      lat: lat,
      lon: lon,
      speed: speed,
      temp: temp,
      shockValue: shockValue,
      batteryLevel: batteryLevel,
      tripState: tripState,
      internalTemp: internalTemp,
      rssi: rssi,
      resetReason: resetReason,
      uptime: uptime,
      isSynced: isSynced,
      syncedAt: syncedAt,
      wifiSsid: wifiSsid,
      wifiSignal: wifiSignal,
    );
  }
}
