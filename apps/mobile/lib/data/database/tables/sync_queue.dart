import 'package:drift/drift.dart';

@DataClassName('SyncOperation')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endpoint => text()();
  TextColumn get payload => text()(); // JSON string
  TextColumn get method => text().withDefault(const Constant('POST'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
