import 'package:drift/drift.dart';

class Trackers extends Table {
  TextColumn get id => text()(); // BLE RemoteId
  TextColumn get name => text()();
  DateTimeColumn get lastSeen => dateTime()();

  // Latest Telemetry Snapshot
  RealColumn get batteryLevel => real().withDefault(const Constant(0.0))();
  RealColumn get temp => real().withDefault(const Constant(0.0))();
  IntColumn get shockValue => integer().withDefault(const Constant(0))();
  TextColumn get additionalTemps => text().nullable()();
  RealColumn get batteryDrop => real().nullable()();

  // QC / Status
  TextColumn get status =>
      text().withDefault(const Constant('Unknown'))(); // Active, Inactive, etc.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
