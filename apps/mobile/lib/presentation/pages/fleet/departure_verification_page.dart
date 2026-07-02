import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/core/utils/telemetry_display.dart';
import 'package:last_mile_tracker/domain/models/fleet_tracker.dart';
import 'package:last_mile_tracker/presentation/providers/fleet_tracker_provider.dart';
import 'package:last_mile_tracker/logic/active_load_service.dart';
import 'package:last_mile_tracker/logic/trip_service.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class DepartureVerificationPage extends ConsumerWidget {
  const DepartureVerificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetTrackersAsync = ref.watch(fleetTrackersProvider);
    final activeIds = ref.watch(activeLoadIdsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          fleetTrackersAsync.when(
            data: (allTrackers) {
              final myTrackers = allTrackers
                  .where((t) => activeIds.contains(t.id))
                  .toList();
              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pre-Departure Check', style: AppTheme.heading1),
                          const SizedBox(height: 8),
                          Text(
                            'Verify all assigned trackers are nearby and broadcasting telemetry before starting your trip.',
                            style: AppTheme.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tracker = myTrackers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VerificationItem(tracker: tracker),
                        );
                      }, childCount: myTrackers.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 150)),
                ],
              );
            },
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
          const FloatingHeader(title: 'Verification'),
          _buildBottomAction(context, ref),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, WidgetRef ref) {
    final fleetTrackersAsync = ref.watch(fleetTrackersProvider);
    final activeIds = ref.watch(activeLoadIdsProvider);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: fleetTrackersAsync.maybeWhen(
          data: (allTrackers) {
            final myTrackers = allTrackers
                .where((t) => activeIds.contains(t.id))
                .toList();
            final inRangeCount = myTrackers.where((t) => t.isInRange).length;
            final isComplete =
                inRangeCount == myTrackers.length && myTrackers.isNotEmpty;

            return CupertinoButton(
              color: isComplete ? AppTheme.success : AppTheme.textSecondary,
              disabledColor: CupertinoDynamicColor.resolve(AppTheme.textSecondary, context)
                  .withValues(alpha: 0.3),
              onPressed: isComplete
                  ? () async {
                      HapticFeedback.mediumImpact();
                      await ref.read(tripServiceProvider.notifier).startTrip();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  : null,
              child: Text(
                isComplete ? 'START TRIP' : 'COMPLETE CHECKLIST',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _VerificationItem extends StatelessWidget {
  final FleetTracker tracker;

  const _VerificationItem({required this.tracker});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: tracker.isInRange
            ? AppTheme.success
            : CupertinoDynamicColor.resolve(AppTheme.critical, context).withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                tracker.isInRange ? AppTheme.success : AppTheme.critical,
                context,
              ).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tracker.isInRange
                  ? CupertinoIcons.check_mark
                  : CupertinoIcons.wifi_slash,
              color: tracker.isInRange ? AppTheme.success : AppTheme.critical,
              size: 18,
            ),
          ).animate(target: tracker.isInRange ? 1 : 0).scale(duration: 300.ms),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tracker.name, style: AppTheme.title),
                Text(
                  tracker.isInRange
                      ? 'In Range (${TelemetryDisplay.signalLabel(tracker.rssi)})'
                      : 'Searching...',
                  style: AppTheme.caption.copyWith(
                    color: tracker.isInRange
                        ? AppTheme.success
                        : AppTheme.critical,
                  ),
                ),
              ],
            ),
          ),
          if (tracker.isInRange)
            Row(
              children: [
                const Icon(
                  CupertinoIcons.battery_100,
                  size: 14,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.thermometer,
                  size: 14,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
