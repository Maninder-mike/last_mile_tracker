import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/domain/models/notification.dart';
import 'package:last_mile_tracker/presentation/providers/notification_provider.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:flutter/services.dart';
import 'package:last_mile_tracker/presentation/widgets/swipe_action_cell.dart';
import 'package:last_mile_tracker/presentation/widgets/entrance_animation.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 60,
                    bottom: 100,
                    left: 16,
                    right: 16,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return EntranceAnimation(
                      index: index,
                      child: _NotificationTile(
                        notification: notifications[index],
                      ),
                    );
                  },
                ),
          FloatingHeader(
            title: 'Alert History',
            showBackButton: true,
            wrapTrailing: false,
            trailing: notifications.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.critical),
                    ),
                    onPressed: () =>
                        ref.read(notificationProvider.notifier).clearAll(),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.bell_slash,
            size: 64,
            color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No new alerts',
            style: AppTheme.body.copyWith(color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getColor();
    final icon = _getIcon();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwipeActionCell(
        groupTag: notification.id,
        startActions: [
          createSwipeAction(
            icon: notification.isRead
                ? CupertinoIcons.check_mark_circled
                : CupertinoIcons.check_mark_circled_solid,
            label: notification.isRead ? 'Unread' : 'Read',
            color: CupertinoTheme.of(context).primaryColor,
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (notification.isRead) {
                // Potential feature: Mark as unread
              } else {
                ref
                    .read(notificationProvider.notifier)
                    .markAsRead(notification.id);
              }
            },
          ),
        ],
        endActions: [
          createSwipeAction(
            icon: CupertinoIcons.trash,
            label: 'Delete',
            color: AppTheme.critical,
            onPressed: () {
              HapticFeedback.heavyImpact();
              ref.read(notificationProvider.notifier).remove(notification.id);
            },
          ),
        ],
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(notificationProvider.notifier).markAsRead(notification.id);
          },
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(notification.title, style: AppTheme.heading2),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: CupertinoTheme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: AppTheme.body.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(notification.timestamp),
                        style: AppTheme.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.info:
        return CupertinoColors.activeBlue;
      case NotificationType.warning:
        return AppTheme.warning;
      case NotificationType.critical:
        return AppTheme.critical;
    }
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.info:
        return CupertinoIcons.info;
      case NotificationType.warning:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case NotificationType.critical:
        return CupertinoIcons.clear_circled;
    }
  }
}
