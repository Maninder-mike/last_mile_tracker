import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<int> enqueueOperation(SyncQueueCompanion operation) {
    return into(syncQueue).insert(operation);
  }

  Future<List<SyncOperation>> getPendingOperations() {
    return (select(syncQueue)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
        ]))
        .get();
  }

  Future<void> removeOperation(int id) {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<void> incrementRetryCount(int id) async {
    final op = await (select(
      syncQueue,
    )..where((t) => t.id.equals(id))).getSingle();
    await update(syncQueue).replace(op.copyWith(retryCount: op.retryCount + 1));
  }
}
