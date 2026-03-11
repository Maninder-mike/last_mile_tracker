import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/data/database/app_database.dart';
import 'package:last_mile_tracker/data/database/daos/sensor_dao.dart';
import 'package:last_mile_tracker/data/database/daos/tracker_dao.dart';
import 'package:last_mile_tracker/data/database/daos/alert_dao.dart';
import 'package:last_mile_tracker/data/database/daos/trip_dao.dart';
import 'package:lmt_models/lmt_models.dart' as models;

// part 'database_providers.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final sensorDaoProvider = Provider<SensorDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.sensorDao;
});

final trackerDaoProvider = Provider<TrackerDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.trackerDao;
});

final alertDaoProvider = Provider<AlertDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.alertDao;
});

final tripDaoProvider = Provider<TripDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.tripDao;
});

final trackerProvider = StreamProvider.family<Tracker?, String>((ref, id) {
  final dao = ref.watch(trackerDaoProvider);
  return dao.watchTracker(id);
});

final latestReadingProvider = StreamProvider<models.SensorReading?>((ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchLatestReading().map((r) => r?.toModel());
});

final recentReadingsProvider = StreamProvider<List<models.SensorReading>>((
  ref,
) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchLatestReadings().map(
    (list) => list.map((r) => r.toModel()).toList(),
  );
});

final recentPathProvider = StreamProvider<List<models.SensorReading>>((ref) {
  final dao = ref.watch(sensorDaoProvider);
  return dao.watchRecentPath().map(
    (list) => list.map((r) => r.toModel()).toList(),
  );
});

final allAlertsProvider = StreamProvider<List<Alert>>((ref) {
  return ref.watch(alertDaoProvider).watchAllAlerts();
});

final unreadAlertsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(alertDaoProvider).watchUnreadCount();
});

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
