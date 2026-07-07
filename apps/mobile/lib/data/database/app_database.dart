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
import 'daos/trip_dao.dart';
import 'daos/sync_queue_dao.dart';

import 'tables/alerts.dart';
import 'tables/trackers.dart';
import 'tables/sync_queue.dart';
import '../../core/utils/file_logger.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [SensorReadings, Trips, Trackers, Alerts, SyncQueue],
  daos: [SensorDao, TrackerDao, AlertDao, TripDao, SyncQueueDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  SensorDao get sensorDao => SensorDao(this);
  @override
  TrackerDao get trackerDao => TrackerDao(this);
  @override
  AlertDao get alertDao => AlertDao(this);
  @override
  TripDao get tripDao => TripDao(this);
  @override
  SyncQueueDao get syncQueueDao => SyncQueueDao(this);

  @override
  int get schemaVersion => 14;

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
      if (from < 7) {
        try {
          await m.addColumn(trackers, trackers.lat);
        } catch (e) {
          FileLogger.log('Migration: lat column already exists or error: $e');
        }
        try {
          await m.addColumn(trackers, trackers.lon);
        } catch (e) {
          FileLogger.log('Migration: lon column already exists or error: $e');
        }
      }
      if (from < 8) {
        if (from >= 6) {
          // Users on v6/v7 have 'batDrop' column. We need 'batteryDrop'.
          // We add 'batteryDrop' as a new column. 'batDrop' becomes orphaned.
          try {
            await m.addColumn(trackers, trackers.batteryDrop);
          } catch (e) {
            FileLogger.log(
              'Migration: batteryDrop column already exists or error: $e',
            );
          }
        }
      }
      if (from < 9) {
        await m.addColumn(trackers, trackers.internalTemp);
        await m.addColumn(trackers, trackers.speed);
        await m.addColumn(trackers, trackers.tripState);
        await m.addColumn(trackers, trackers.resetReason);
        await m.addColumn(trackers, trackers.uptime);
      }
      if (from < 10) {
        await m.addColumn(trackers, trackers.isFavorite);
      }
      if (from < 11) {
        await m.createTable(syncQueue);
      }
      if (from < 12) {
        await m.addColumn(sensorReadings, sensorReadings.deviceId);
      }
      if (from < 13) {
        await m.addColumn(trackers, trackers.customName);
      }
      if (from < 14) {
        await m.addColumn(sensorReadings, sensorReadings.clientUuid);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      try {
        final result = await customSelect('PRAGMA integrity_check(1)').getSingle();
        final check = result.read<String>('integrity_check');
        if (check != 'ok') {
          FileLogger.log('AppDatabase: Integrity check failed: $check');
        } else {
          FileLogger.log('AppDatabase: Integrity check passed.');
        }
      } catch (e) {
        FileLogger.log('AppDatabase: Error running integrity check: $e');
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'milow_driver.sqlite'));
    
    try {
      // In background creation should succeed unless the directory is unwritable or file is locked
      return NativeDatabase.createInBackground(file);
    } catch (e) {
      FileLogger.log("AppDatabase: Database initialization error: $e. Performing self-healing delete.");
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (delError) {
        FileLogger.log("AppDatabase: Failed to delete corrupted database: $delError");
      }
      return NativeDatabase.createInBackground(file);
    }
  });
}
