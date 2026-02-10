import 'package:drift/drift.dart';

@TableIndex(name: 'sensor_timestamp', columns: {#timestamp})
@TableIndex(name: 'sensor_synced', columns: {#isSynced})
class SensorReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();

  // GPS Data
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get speed => real()(); // in km/h

  // Sensors
  RealColumn get temp => real()();
  IntColumn get shockValue => integer()();
  RealColumn get batteryLevel => real().withDefault(const Constant(0.0))();
  IntColumn get tripState => integer().withDefault(const Constant(0))();
  RealColumn get internalTemp => real().withDefault(const Constant(0.0))();

  // Diagnostics
  IntColumn get rssi => integer().nullable()();
  IntColumn get resetReason => integer().nullable()();
  IntColumn get uptime => integer().nullable()();

  // Sync Status
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
