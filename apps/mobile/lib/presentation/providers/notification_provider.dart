import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification.dart';

class NotificationNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    return AppNotification.mockData;
  }

  void addNotification(AppNotification notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void clearAll() {
    state = [];
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, List<AppNotification>>(() {
      return NotificationNotifier();
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).where((n) => !n.isRead).length;
});
