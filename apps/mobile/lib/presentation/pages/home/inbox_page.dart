import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../providers/database_providers.dart';
import '../../widgets/glass_container.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(allAlertsProvider);
    final alertDao = ref.watch(alertDaoProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Inbox'),
            backgroundColor: AppTheme.background.withValues(alpha: 0.8),
            border: null,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('Read All'),
              onPressed: () => alertDao.markAllAsRead(),
            ),
          ),
          SliverToBoxAdapter(
            child: alertsAsync.when(
              data: (alerts) => alerts.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        const SizedBox(height: 12),
                        ...alerts.map((alert) => _AlertTile(alert: alert)),
                        const SizedBox(height: 100), // Height for bottom nav
                      ],
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CupertinoActivityIndicator(),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        Icon(
          CupertinoIcons.tray_fill,
          size: 64,
          color: AppTheme.textSecondary.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'No messages yet',
          style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _AlertTile extends ConsumerWidget {
  final Alert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertDao = ref.watch(alertDaoProvider);
    final isCritical = alert.type == 'critical';
    final accentColor = CupertinoTheme.of(context).primaryColor;

    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Dismissible(
            key: ValueKey(alert.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => alertDao.deleteAlert(alert.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: CupertinoColors.destructiveRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(CupertinoIcons.delete, color: Colors.white),
            ),
            child: GestureDetector(
              onTap: () => alertDao.markAsRead(alert.id),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                color: alert.isRead
                    ? AppTheme.surfaceGlass
                    : AppTheme.surface.withValues(alpha: 0.5),
                border: alert.isRead
                    ? null
                    : Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIcon(isCritical, accentColor),
                    const SizedBox(width: 12),
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
                                  style: AppTheme.title.copyWith(
                                    fontWeight: alert.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                timeago.format(alert.timestamp),
                                style: AppTheme.caption.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.message,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!alert.isRead)
                      Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: 1000.ms,
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.2, 1.2),
                            end: const Offset(1, 1),
                          ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn();
  }

  Widget _buildIcon(bool isCritical, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isCritical ? CupertinoColors.destructiveRed : accentColor)
            .withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCritical
            ? CupertinoIcons.exclamationmark_triangle_fill
            : CupertinoIcons.bell_fill,
        color: isCritical ? CupertinoColors.destructiveRed : accentColor,
        size: 18,
      ),
    );
  }
}
