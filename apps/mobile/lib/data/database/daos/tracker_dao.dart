import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/trackers.dart';

part 'tracker_dao.g.dart';

@DriftAccessor(tables: [Trackers])
class TrackerDao extends DatabaseAccessor<AppDatabase> with _$TrackerDaoMixin {
  TrackerDao(super.db);

  // Upsert a tracker (insert or update)
  Future<void> upsertTracker(TrackersCompanion tracker) async {
    await into(trackers).insertOnConflictUpdate(tracker);
  }

  // Get all trackers stream
  Stream<List<Tracker>> watchAllTrackers() {
    return (select(trackers)..orderBy([
          (t) => OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  // Get a single tracker
  Future<Tracker?> getTracker(String id) {
    return (select(trackers)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Watch a single tracker
  Stream<Tracker?> watchTracker(String id) {
    return (select(
      trackers,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  // Get active trackers (seen in last 5 minutes)
  Future<List<Tracker>> getActiveTrackers() {
    final threshold = DateTime.now().subtract(const Duration(minutes: 5));
    return (select(
      trackers,
    )..where((t) => t.lastSeen.isBiggerThanValue(threshold))).get();
  }
}
