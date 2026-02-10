import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/sensor_readings.dart';
import 'tables/trips.dart';
import 'daos/sensor_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SensorReadings, Trips], daos: [SensorDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
