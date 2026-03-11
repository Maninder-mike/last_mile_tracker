import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_providers.dart';
import '../../data/database/app_database.dart';

final alertsStreamProvider = StreamProvider<List<Alert>>((ref) {
  final dao = ref.watch(alertDaoProvider);
  return dao.watchAllAlerts();
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(alertDaoProvider);
  return dao.watchUnreadCount();
});

final notificationManagerProvider = NotifierProvider<NotificationManager, void>(
  () {
    return NotificationManager();
  },
);

class NotificationManager extends Notifier<void> {
  @override
  void build() {}

  Future<void> markAsRead(int id) async {
    final dao = ref.read(alertDaoProvider);
    await dao.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final dao = ref.read(alertDaoProvider);
    await dao.markAllAsRead();
  }

  Future<void> deleteAlert(int id) async {
    final dao = ref.read(alertDaoProvider);
    await dao.deleteAlert(id);
  }

  Future<void> clearAll() async {
    final dao = ref.read(alertDaoProvider);
    await dao.deleteAllAlerts();
  }
}
