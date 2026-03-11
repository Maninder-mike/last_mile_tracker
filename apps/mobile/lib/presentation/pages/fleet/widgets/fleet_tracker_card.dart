import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/domain/models/fleet_tracker.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

class FleetTrackerCard extends StatelessWidget {
  final FleetTracker tracker;
  final VoidCallback onTap;

  const FleetTrackerCard({
    super.key,
    required this.tracker,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSignalIndicator(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracker.name,
                        style: AppTheme.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tracker.trackingNumber != null)
                        Text(tracker.trackingNumber!, style: AppTheme.caption),
                    ],
                  ),
                ),
                _buildStatusBadge(statusColor),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTelemetryItem(
                  icon: CupertinoIcons.battery_100,
                  value: tracker.batteryLevel != null
                      ? '${tracker.batteryLevel!.toInt()}%'
                      : '--',
                  color: (tracker.batteryLevel ?? 100) < 20
                      ? AppTheme.critical
                      : AppTheme.success,
                ),
                _buildTelemetryItem(
                  icon: CupertinoIcons.thermometer,
                  value: tracker.temp != null
                      ? '${tracker.temp!.toStringAsFixed(1)}°C'
                      : '--',
                  color: (tracker.temp ?? 0) > 30
                      ? AppTheme.warning
                      : CupertinoTheme.of(context).primaryColor,
                ),
                _buildTelemetryItem(
                  icon: CupertinoIcons.time,
                  value: _formatTimeAgo(tracker.lastSeen),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalIndicator() {
    if (!tracker.isInRange) {
      return const Icon(
        CupertinoIcons.wifi_slash,
        size: 16,
        color: AppTheme.textSecondary,
      );
    }

    final rssi = tracker.rssi ?? -100;
    IconData icon;
    Color color;

    if (rssi > -60) {
      icon = CupertinoIcons.wifi;
      color = AppTheme.success;
    } else if (rssi > -80) {
      icon = CupertinoIcons.wifi;
      color = AppTheme.warning;
    } else {
      icon = CupertinoIcons.wifi;
      color = AppTheme.critical;
    }

    return Icon(icon, size: 16, color: color);
  }

  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        tracker.isInRange ? 'NEARBY' : 'REMOTE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTelemetryItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTheme.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (!tracker.isInRange) return AppTheme.textSecondary;
    if (tracker.status == 'critical') return AppTheme.critical;
    if (tracker.status == 'warning') return AppTheme.warning;
    return AppTheme.success;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
