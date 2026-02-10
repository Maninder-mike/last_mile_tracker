import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sensor_readings.dart';

part 'sensor_dao.g.dart';

@DriftAccessor(tables: [SensorReadings])
class SensorDao extends DatabaseAccessor<AppDatabase> with _$SensorDaoMixin {
  SensorDao(super.db);

  // Insert a new reading
  Future<int> insertReading(SensorReadingsCompanion reading) {
    return into(sensorReadings).insert(reading);
  }

  // Batch insert readings for high-frequency data (performance optimization)
  Future<void> insertReadingsBatch(
    List<SensorReadingsCompanion> readings,
  ) async {
    await batch((b) => b.insertAll(sensorReadings, readings));
  }

  // Delete all readings
  Future<void> deleteAllReadings() {
    return delete(sensorReadings).go();
  }

  // Data retention policy: Delete synced readings older than X duration
  Future<int> deleteSyncedReadingsOlderThan(Duration duration) {
    final threshold = DateTime.now().subtract(duration);
    return (delete(sensorReadings)..where(
          (t) =>
              t.isSynced.equals(true) &
              t.timestamp.isSmallerThanValue(threshold),
        ))
        .go();
  }

  // Stream the latest 50 readings for the logs page
  Stream<List<SensorReading>> watchLatestReadings() {
    return (select(sensorReadings)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(50))
        .watch();
  }

  // Stream the single latest reading for the dashboard stats
  Stream<SensorReading?> watchLatestReading() {
    return (select(sensorReadings)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  // Stream recent path (last 500 points) for map overlay
  Stream<List<SensorReading>> watchRecentPath() {
    return (select(sensorReadings)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(500))
        .watch();
  }

  // Get unsynced readings for upload
  Future<List<SensorReading>> getUnsyncedReadings([int? limit]) {
    final query = select(sensorReadings)
      ..where((t) => t.isSynced.equals(false));
    if (limit != null) {
      query.limit(limit);
    }
    return query.get();
  }

  // Mark readings as synced
  Future<void> markAsSynced(List<int> ids) async {
    await (update(sensorReadings)..where((t) => t.id.isIn(ids))).write(
      SensorReadingsCompanion(
        isSynced: const Value(true),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }
}
