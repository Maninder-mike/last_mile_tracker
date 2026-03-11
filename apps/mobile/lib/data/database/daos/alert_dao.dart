import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/alerts.dart';

part 'alert_dao.g.dart';

// part 'alert_dao.g.dart';

@DriftAccessor(tables: [Alerts])
class AlertDao extends DatabaseAccessor<AppDatabase> {
  AlertDao(super.db);

  TableInfo<Alerts, Alert> get _alerts => db.alerts;

  Future<void> insertAlert(AlertsCompanion alert) async {
    await into(_alerts).insert(alert);
  }

  Stream<List<Alert>> watchAllAlerts() {
    return (select(
      _alerts,
    )..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).watch();
  }

  Stream<int> watchUnreadCount() {
    return (select(
      _alerts,
    )..where((a) => a.isRead.equals(false))).watch().map((list) => list.length);
  }

  Future<void> markAllAsRead() async {
    await (update(_alerts)).write(const AlertsCompanion(isRead: Value(true)));
  }

  // Mark specific alert as read
  Future<void> markAsRead(int id) async {
    await (update(_alerts)..where((t) => t.id.equals(id))).write(
      const AlertsCompanion(isRead: Value(true)),
    );
  }

  Future<void> deleteAlert(int id) async {
    await (delete(_alerts)..where((a) => a.id.equals(id))).go();
  }

  Future<void> deleteAllAlerts() async {
    await delete(_alerts).go();
  }
}
