import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/alerts.dart';

part 'alert_dao.g.dart';

@DriftAccessor(tables: [Alerts])
class AlertDao extends DatabaseAccessor<AppDatabase> with _$AlertDaoMixin {
  AlertDao(super.db);

  Future<void> insertAlert(AlertsCompanion alert) async {
    await into(alerts).insert(alert);
  }

  Stream<List<Alert>> watchUnreadAlerts() {
    return (select(alerts)..where((a) => a.isRead.equals(false))).watch();
  }

  Future<void> markAsRead(int id) async {
    await (update(alerts)..where((a) => a.id.equals(id))).write(
      const AlertsCompanion(isRead: Value(true)),
    );
  }
}
