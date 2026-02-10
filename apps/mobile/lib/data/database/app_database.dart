import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/sensor_readings.dart';
import 'tables/trips.dart';
import 'daos/sensor_dao.dart';
import 'daos/tracker_dao.dart';
import 'daos/alert_dao.dart';

import 'tables/alerts.dart';
import 'tables/trackers.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [SensorReadings, Trips, Trackers, Alerts],
  daos: [SensorDao, TrackerDao, AlertDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Add missing columns to sensor_readings if upgrading from v1
        await m.addColumn(sensorReadings, sensorReadings.batteryLevel);
        await m.addColumn(sensorReadings, sensorReadings.tripState);
        await m.addColumn(sensorReadings, sensorReadings.internalTemp);
        await m.addColumn(sensorReadings, sensorReadings.rssi);
        await m.addColumn(sensorReadings, sensorReadings.resetReason);
        await m.addColumn(sensorReadings, sensorReadings.uptime);
        await m.addColumn(sensorReadings, sensorReadings.wifiSsid);
        await m.addColumn(sensorReadings, sensorReadings.wifiSignal);
      }
      if (from < 3) {
        await m.createTable(trackers);
      }
      if (from < 4) {
        await m.createTable(alerts);
      }
      if (from < 5) {
        await m.addColumn(sensorReadings, sensorReadings.additionalTemps);
        await m.addColumn(sensorReadings, sensorReadings.batteryDrop);
      }
      if (from < 6) {
        await m.addColumn(trackers, trackers.additionalTemps);
        await m.addColumn(trackers, trackers.batteryDrop);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'milow_driver.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
