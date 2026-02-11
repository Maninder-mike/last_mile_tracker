import 'package:drift/drift.dart';

class Trackers extends Table {
  TextColumn get id => text()(); // BLE RemoteId
  TextColumn get name => text()();
  DateTimeColumn get lastSeen => dateTime()();

  // Latest Telemetry Snapshot
  // Latest Telemetry Snapshot
  RealColumn get batteryLevel => real().nullable()();
  RealColumn get temp => real().nullable()();
  IntColumn get shockValue => integer().nullable()();
  TextColumn get additionalTemps => text().nullable()();
  RealColumn get batteryDrop => real().nullable()();

  // GPS Data
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();

  // New Telemetry Fields
  RealColumn get internalTemp => real().nullable()();
  RealColumn get speed => real().nullable()();
  IntColumn get tripState => integer().nullable()();
  IntColumn get resetReason => integer().nullable()();
  IntColumn get uptime => integer().nullable()();

  // QC / Status
  TextColumn get status => text().withDefault(
    const Constant('Unknown'),
  )(); // Keep status with default
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
