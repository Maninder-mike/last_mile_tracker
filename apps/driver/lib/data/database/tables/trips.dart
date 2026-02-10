import 'package:drift/drift.dart';

class Trips extends Table {
  TextColumn get id => text()(); // UUID
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();

  RealColumn get distance => real().withDefault(const Constant(0.0))();
  RealColumn get maxSpeed => real().withDefault(const Constant(0.0))();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
