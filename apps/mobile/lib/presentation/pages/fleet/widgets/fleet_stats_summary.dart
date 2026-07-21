import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/domain/models/fleet_tracker.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/core/constants/ble_constants.dart';

class FleetStatsSummary extends StatelessWidget {
  final List<FleetTracker> trackers;

  const FleetStatsSummary({super.key, required this.trackers});

  @override
  Widget build(BuildContext context) {
    final activeShipments = trackers.where((t) => t.shipmentId != null).length;
    final atRisk = trackers
        .where(
          (t) =>
              t.status == 'critical' ||
              (t.batteryLevel != null &&
                  BleConstants.batteryVoltageToPercent(t.batteryLevel!) < 15),
        )
        .length;
    final nearby = trackers.where((t) => t.isInRange).length;

    // Average temperature calculation
    final temps = trackers.map((t) => t.temp).whereType<double>().toList();
    final avgTemp = temps.isNotEmpty
        ? temps.reduce((a, b) => a + b) / temps.length
        : 0.0;

    Widget atRiskCard = _buildStatCard(
      context: context,
      label: 'At Risk',
      value: '$atRisk',
      icon: CupertinoIcons.exclamationmark_triangle,
      color: AppTheme.critical,
    );

    if (atRisk > 0) {
      atRiskCard = atRiskCard
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .custom(
            duration: 1500.ms,
            builder: (context, val, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.critical.withValues(alpha: 0.25 * val),
                    blurRadius: 8.0 * val,
                    spreadRadius: 1.0 * val,
                  ),
                ],
              ),
              child: child,
            ),
          );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            context: context,
            label: 'Shipments',
            value: '$activeShipments',
            icon: CupertinoIcons.cube_box,
            color: CupertinoTheme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          atRiskCard,
          const SizedBox(width: 12),
          _buildStatCard(
            context: context,
            label: 'Nearby',
            value: '$nearby',
            icon: CupertinoIcons.wifi,
            color: AppTheme.success,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context: context,
            label: 'Avg Temp',
            value: '${avgTemp.toStringAsFixed(1)}°C',
            icon: CupertinoIcons.thermometer,
            color: CupertinoTheme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: resolvedColor.withValues(alpha: 0.08),
      border: Border.all(
        color: resolvedColor.withValues(alpha: 0.25),
        width: 1.2,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: resolvedColor,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTheme.title.copyWith(
                  fontSize: 18,
                  color: AppTheme.resolvedTextPrimary(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.resolvedTextSecondary(context).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
