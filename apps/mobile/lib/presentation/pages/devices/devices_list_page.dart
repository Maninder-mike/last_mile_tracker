import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:last_mile_tracker/presentation/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';

class DevicesListPage extends ConsumerWidget {
  const DevicesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannedDevicesAsync = ref.watch(allTrackersProvider);

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Devices'),
            backgroundColor: Colors.transparent,
            border: null,
            stretch: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: scannedDevicesAsync.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 32.0),
                        child: Text(
                          'No devices found',
                          style: TextStyle(color: CupertinoColors.systemGrey),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tracker = devices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DeviceCard(
                        id: tracker.id,
                        name: tracker.name.isEmpty
                            ? 'Unknown Device'
                            : tracker.name,
                        status: tracker.status, // Use status from DB
                        battery: tracker.batteryLevel.toInt(),
                        lastSeen: _formatLastSeen(tracker.lastSeen),
                        isCritical:
                            tracker.batteryLevel < 20 || tracker.shockValue > 0,
                        type: 'Tracker', // Default for now
                      ),
                    );
                  }, childCount: devices.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (err, stack) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _DeviceCard extends StatelessWidget {
  final String id;
  final String name;
  final String status;
  final int battery;
  final String lastSeen;
  final bool isCritical;
  final String type;

  const _DeviceCard({
    required this.id,
    required this.name,
    required this.status,
    required this.battery,
    required this.lastSeen,
    this.isCritical = false,
    this.type = 'Tracker',
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                AppTheme.primary,
                context,
              ).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == 'Gateway' ? CupertinoIcons.wifi : CupertinoIcons.location,
              color: CupertinoDynamicColor.resolve(AppTheme.primary, context),
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
                    Text(name, style: AppTheme.heading2),
                    _StatusBadge(status: status, isCritical: isCritical),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(id, style: AppTheme.caption),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(lastSeen, style: AppTheme.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Icon(
                battery > 20
                    ? CupertinoIcons.battery_100
                    : CupertinoIcons.battery_25,
                size: 16,
                color: battery > 20 ? AppTheme.success : AppTheme.critical,
              ),
              const SizedBox(height: 4),
              Text('$battery%', style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isCritical;

  const _StatusBadge({required this.status, required this.isCritical});

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppTheme.critical : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          color,
          context,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
            color,
            context,
          ).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(color, context),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
