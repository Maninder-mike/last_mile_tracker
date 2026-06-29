import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/fleet_tracker_provider.dart';
import 'package:last_mile_tracker/presentation/providers/notification_provider.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/presentation/widgets/entrance_animation.dart';
import 'package:last_mile_tracker/presentation/pages/notifications/notification_center_page.dart';
import 'package:last_mile_tracker/presentation/pages/devices/device_detail_page.dart';
import 'package:last_mile_tracker/presentation/widgets/connection_status_icon.dart';
import 'widgets/fleet_tracker_card.dart';
import 'widgets/fleet_stats_summary.dart';
import 'widgets/active_load_card.dart';
import 'departure_verification_page.dart';

class FleetOverviewPage extends ConsumerStatefulWidget {
  const FleetOverviewPage({super.key});

  @override
  ConsumerState<FleetOverviewPage> createState() => _FleetOverviewPageState();
}

class _FleetOverviewPageState extends ConsumerState<FleetOverviewPage> {
  @override
  Widget build(BuildContext context) {
    final fleetTrackersAsync = ref.watch(fleetTrackersProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          fleetTrackersAsync.when(
            data: (trackers) => CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    ref.invalidate(fleetTrackersProvider);
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 70,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EntranceAnimation(
                          index: 0,
                          child: FleetStatsSummary(trackers: trackers),
                        ),
                        const SizedBox(height: 24),
                        ActiveLoadCard(
                          allTrackers: trackers,
                          onVerify: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const DepartureVerificationPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Live Fleet Trackers',
                              style: AppTheme.heading2.copyWith(
                                color: AppTheme.resolvedTextPrimary(context),
                              ),
                            ),
                            Text(
                              '${trackers.where((t) => t.isInRange).length} nearby',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tracker = trackers[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      child: EntranceAnimation(
                        index: index + 1,
                        child: FleetTrackerCard(
                          tracker: tracker,
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => DeviceDetailPage(
                                deviceId: tracker.id,
                                name: tracker.name,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: trackers.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          FloatingHeader(
            title: 'Fleet Overview',
            wrapTrailing: false,
            trailing: _buildActionButtons(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ConnectionStatusIcon(),
        const SizedBox(width: 8),
        _NotificationBadge(
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const NotificationCenterPage(),
            ),
          ),
        ),
      ],
    );
  }
} // End of _FleetOverviewPageState

class _NotificationBadge extends ConsumerWidget {
  final VoidCallback onTap;
  const _NotificationBadge({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;

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
              size: 24,
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
