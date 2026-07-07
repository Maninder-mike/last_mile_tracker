import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/notification_provider.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import '../../../data/database/app_database.dart';
import 'package:flutter/services.dart';
import 'package:last_mile_tracker/presentation/widgets/swipe_action_cell.dart';
import 'package:last_mile_tracker/presentation/widgets/entrance_animation.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationCenterPage extends ConsumerStatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  ConsumerState<NotificationCenterPage> createState() =>
      _NotificationCenterPageState();
}

class _NotificationCenterPageState
    extends ConsumerState<NotificationCenterPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsStreamProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          alertsAsync.when(
            data: (alerts) {
              final filteredAlerts = alerts.where((alert) {
                if (_selectedFilter == 'all') return true;
                if (_selectedFilter == 'critical') {
                  return alert.type == 'critical' || alert.type == 'warning';
                }
                if (_selectedFilter == 'proximity') {
                  return alert.type == 'proximity';
                }
                return true;
              }).toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.top + 60,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<String>(
                          groupValue: _selectedFilter,
                          children: const {
                            'all': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('All'),
                            ),
                            'critical': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Critical'),
                            ),
                            'proximity': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Proximity'),
                            ),
                          },
                          onValueChanged: (value) {
                            if (value != null) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedFilter = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  filteredAlerts.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return EntranceAnimation(
                              index: index,
                              child: _NotificationTile(
                                alert: filteredAlerts[index],
                              ),
                            );
                          }, childCount: filteredAlerts.length),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
          FloatingHeader(
            title: 'Alert History',
            showBackButton: true,
            wrapTrailing: false,
            trailing: alertsAsync.maybeWhen(
              data: (alerts) => alerts.isNotEmpty
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: AppTheme.critical),
                      ),
                      onPressed: () => ref
                          .read(notificationManagerProvider.notifier)
                          .clearAll(),
                    )
                  : null,
              orElse: () => null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String text = 'No recent alerts';
    IconData icon = CupertinoIcons.bell_slash;
    if (_selectedFilter == 'critical') {
      text = 'No critical alerts';
      icon = CupertinoIcons.checkmark_shield;
    } else if (_selectedFilter == 'proximity') {
      text = 'No proximity alerts';
      icon = CupertinoIcons.location_slash;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey,
                context,
              ).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: AppTheme.body.copyWith(color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final Alert alert;

  const _NotificationTile({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getColor();
    final icon = _getIcon();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwipeActionCell(
        groupTag: 'alert-${alert.id}',
        startActions: [
          createSwipeAction(
            icon: alert.isRead
                ? CupertinoIcons.check_mark_circled
                : CupertinoIcons.check_mark_circled_solid,
            label: alert.isRead ? 'Unread' : 'Read',
            color: CupertinoTheme.of(context).primaryColor,
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref
                  .read(notificationManagerProvider.notifier)
                  .markAsRead(alert.id);
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
              ref
                  .read(notificationManagerProvider.notifier)
                  .deleteAlert(alert.id);
            },
          ),
        ],
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(notificationManagerProvider.notifier).markAsRead(alert.id);
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
                          Expanded(
                            child: Text(
                              alert.title,
                              style: AppTheme.heading2.copyWith(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!alert.isRead)
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
                        alert.message,
                        style: AppTheme.body.copyWith(
                          color: CupertinoColors.systemGrey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(alert.timestamp),
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
    switch (alert.type) {
      case 'info':
        return CupertinoColors.activeBlue;
      case 'warning':
        return AppTheme.warning;
      case 'critical':
        return AppTheme.critical;
      case 'proximity':
        return CupertinoColors.systemIndigo;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getIcon() {
    switch (alert.type) {
      case 'info':
        return CupertinoIcons.info;
      case 'warning':
        return CupertinoIcons.exclamationmark_triangle_fill;
      case 'critical':
        return CupertinoIcons.clear_circled;
      case 'proximity':
        return CupertinoIcons.location_solid;
      default:
        return CupertinoIcons.bell;
    }
  }
}
