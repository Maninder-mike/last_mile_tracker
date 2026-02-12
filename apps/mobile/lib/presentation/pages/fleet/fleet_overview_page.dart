import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Colors; // Needed for transparent/white/black if not using CupertinoColors
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:last_mile_tracker/presentation/widgets/entrance_animation.dart';
import 'package:last_mile_tracker/presentation/pages/analytics/analytics_page.dart';
import 'package:last_mile_tracker/presentation/pages/notifications/notification_center_page.dart';
import 'package:last_mile_tracker/presentation/providers/notification_provider.dart';

class FleetOverviewPage extends ConsumerStatefulWidget {
  const FleetOverviewPage({super.key});

  @override
  ConsumerState<FleetOverviewPage> createState() => _FleetOverviewPageState();
}

class _FleetOverviewPageState extends ConsumerState<FleetOverviewPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent, // Let MainLayout background show
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(allTrackersProvider);
                  // Simulate some network delay for better UX
                  await Future.delayed(const Duration(milliseconds: 800));
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 60,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // KPI Grid
                      Row(
                        children: [
                          Expanded(
                            child: EntranceAnimation(
                              index: 0,
                              delay: const Duration(milliseconds: 100),
                              child: _KpiCard(
                                title: 'Active Shipments',
                                value: '12',
                                color: AppTheme.primary,
                                icon: CupertinoIcons.cube_box,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.s12),
                          Expanded(
                            child: EntranceAnimation(
                              index: 1,
                              delay: const Duration(milliseconds: 100),
                              child: _KpiCard(
                                title: 'At Risk',
                                value: '3',
                                color: AppTheme.critical,
                                icon: CupertinoIcons.exclamationmark_triangle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.s12),
                      Row(
                        children: [
                          Expanded(
                            child: EntranceAnimation(
                              index: 2,
                              delay: const Duration(milliseconds: 100),
                              child: _KpiCard(
                                title: 'Offline',
                                value: '1',
                                color: AppTheme.textSecondary,
                                icon: CupertinoIcons.wifi_slash,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.s12),
                          Expanded(
                            child: EntranceAnimation(
                              index: 3,
                              delay: const Duration(milliseconds: 100),
                              child: _KpiCard(
                                title: 'Avg Temp',
                                value: '-4°C',
                                color: AppTheme.success,
                                icon: CupertinoIcons.thermometer,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.s32),
                      Text('Requires Attention', style: AppTheme.heading2),
                      const SizedBox(height: AppTheme.s16),

                      // Mock "At Risk" List
                      ...Shipment.mockData
                          .where((s) => s.status == ShipmentStatus.atRisk)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.s12,
                              ),
                              child: EntranceAnimation(
                                index: entry.key,
                                child: _ShipmentCard(shipment: entry.value),
                              ),
                            ),
                          ),

                      // Bottom padding for floating navbar
                    ],
                  ),
                ),
              ),
            ],
          ),
          const FloatingHeader(title: 'Fleet Overview'),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Row(
              children: [
                _NotificationBadge(
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const NotificationCenterPage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(
                        context,
                      ).barBackgroundColor.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.graph_square,
                      color: CupertinoTheme.of(context).primaryColor,
                      size: 22,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const AnalyticsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBadge extends ConsumerWidget {
  final VoidCallback onTap;

  const _NotificationBadge({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(
                context,
              ).barBackgroundColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.bell,
              color: CupertinoTheme.of(context).primaryColor,
              size: 22,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.critical,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = CupertinoDynamicColor.resolve(color, context);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: effectiveColor, size: 24),
              // Trend indicator could go here
            ],
          ),
          const SizedBox(height: AppTheme.s8),
          Text(
            value,
            style: AppTheme.heading1.copyWith(
              fontSize: 28,
              color: effectiveColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final Shipment shipment;

  const _ShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(shipment.status);
    final effectiveStatusColor = CupertinoDynamicColor.resolve(
      statusColor,
      context,
    );

    return GlassContainer(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: effectiveStatusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(shipment.trackingNumber, style: AppTheme.title),
                    Text(
                      '${DateTime.now().difference(shipment.lastUpdate ?? DateTime.now()).inMinutes}m ago',
                      style: AppTheme.caption.copyWith(
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${shipment.origin} -> ${shipment.destination}',
                  style: AppTheme.body,
                ),
                const SizedBox(height: 4),
                Text(
                  shipment.status.name.toUpperCase(),
                  style: AppTheme.caption.copyWith(
                    color: effectiveStatusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.chevron_right,
            color: CupertinoColors.systemGrey2,
            size: 14,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.inTransit:
        return AppTheme.primary;
      case ShipmentStatus.delivered:
        return AppTheme.success;
      case ShipmentStatus.delayed:
        return AppTheme.warning;
      case ShipmentStatus.atRisk:
        return AppTheme.critical;
    }
  }
}
