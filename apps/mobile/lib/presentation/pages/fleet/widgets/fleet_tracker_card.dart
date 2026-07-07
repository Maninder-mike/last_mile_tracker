import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/domain/models/fleet_tracker.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/core/constants/ble_constants.dart';

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
    final statusColor = _getStatusColor(context);
    final isWiredPower = tracker.batteryLevel != null && tracker.batteryLevel! < 1.0;
    final batPercent = tracker.batteryLevel != null 
        ? BleConstants.batteryVoltageToPercent(tracker.batteryLevel!) 
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar, Info, Status Badge & Chevron
            Row(
              children: [
                _buildDeviceAvatar(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracker.displayName,
                        style: AppTheme.title.copyWith(
                          color: AppTheme.resolvedTextPrimary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (tracker.trackingNumber != null)
                        Text(
                          'Track: ${tracker.trackingNumber!}',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.resolvedTextSecondary(context),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          tracker.id.toUpperCase(),
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.resolvedTextSecondary(context).withValues(alpha: 0.6),
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(context, statusColor),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimeAgo(tracker.lastSeen),
                      style: AppTheme.caption.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.resolvedTextSecondary(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 13,
                  color: AppTheme.resolvedTextSecondary(context).withValues(alpha: 0.4),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // Inline Telemetry Row: Battery, Temp, and Signal Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Battery
                _buildMinimalMetric(
                  context: context,
                  icon: isWiredPower 
                      ? CupertinoIcons.battery_charging 
                      : (batPercent >= 80 ? CupertinoIcons.battery_100 : CupertinoIcons.battery_25),
                  value: tracker.batteryLevel != null 
                      ? (isWiredPower ? 'USB' : '$batPercent%') 
                      : '--',
                  color: tracker.batteryLevel != null 
                      ? (isWiredPower 
                          ? AppTheme.success 
                          : (batPercent < 20 ? AppTheme.critical : AppTheme.success)) 
                      : AppTheme.resolvedTextSecondary(context),
                ),
                
                // 2. Core Temp
                _buildMinimalMetric(
                  context: context,
                  icon: CupertinoIcons.thermometer,
                  value: tracker.temp != null 
                      ? '${tracker.temp!.toStringAsFixed(1)}°C' 
                      : '--',
                  color: tracker.temp != null 
                      ? (tracker.temp! > 30.0 ? AppTheme.critical : AppTheme.success) 
                      : AppTheme.resolvedTextSecondary(context),
                ),

                // 3. Signal Bars
                _buildSignalBars(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceAvatar(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final resolvedColor = CupertinoDynamicColor.resolve(statusColor, context);
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.resolvedTextPrimary(context).withValues(alpha: 0.06),
            AppTheme.resolvedTextPrimary(context).withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.resolvedTextSecondary(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            CupertinoIcons.location_north_fill,
            size: 16,
            color: AppTheme.resolvedTextPrimary(context).withValues(alpha: 0.7),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: resolvedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: resolvedColor.withValues(alpha: 0.3),
                    blurRadius: 3,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBars(BuildContext context) {
    if (!tracker.isInRange) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.wifi_slash, 
            size: 13, 
            color: AppTheme.resolvedTextSecondary(context).withValues(alpha: 0.4)
          ),
          const SizedBox(width: 4),
          Text(
            'Offline', 
            style: AppTheme.caption.copyWith(
              fontSize: 11, 
              fontWeight: FontWeight.w500
            )
          ),
        ],
      );
    }
    
    final rssi = tracker.rssi ?? -100;
    final int activeBars;
    final Color barColor;

    if (rssi > -60) {
      activeBars = 4;
      barColor = AppTheme.success;
    } else if (rssi > -75) {
      activeBars = 3;
      barColor = AppTheme.warning;
    } else if (rssi > -90) {
      activeBars = 2;
      barColor = AppTheme.warning;
    } else {
      activeBars = 1;
      barColor = AppTheme.critical;
    }

    final resolvedColor = CupertinoDynamicColor.resolve(barColor, context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (index) {
            final barHeight = 2.5 + (index * 2.5); // 2.5, 5.0, 7.5, 10.0 px
            final isActive = index < activeBars;
            return Container(
              width: 2.0,
              height: barHeight,
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                color: isActive 
                    ? resolvedColor 
                    : AppTheme.resolvedTextSecondary(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(0.75),
              ),
            );
          }),
        ),
        const SizedBox(width: 6),
        Text(
          '$rssi dBm',
          style: AppTheme.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.resolvedTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, Color color) {
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Text(
        tracker.isInRange ? 'NEARBY' : 'REMOTE',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: resolvedColor,
        ),
      ),
    );
  }

  Widget _buildMinimalMetric({
    required BuildContext context,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: resolvedColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.resolvedTextPrimary(context),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context) {
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
