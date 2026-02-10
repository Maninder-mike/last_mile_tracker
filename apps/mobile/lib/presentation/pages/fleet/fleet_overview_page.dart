import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Colors; // Needed for transparent/white/black if not using CupertinoColors
import 'package:last_mile_tracker/presentation/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';

class FleetOverviewPage extends StatelessWidget {
  const FleetOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent, // Let MainLayout background show
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Fleet Overview'),
            backgroundColor: Colors.transparent,
            border: null, // No border for cleaner look
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Grid
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'Active Shipments',
                          value: '12',
                          color: AppTheme.primary,
                          icon: CupertinoIcons.cube_box,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'At Risk',
                          value: '3',
                          color: AppTheme.critical,
                          icon: CupertinoIcons.exclamationmark_triangle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'Offline',
                          value: '1',
                          color: AppTheme.textSecondary,
                          icon: CupertinoIcons.wifi_slash,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'Avg Temp',
                          value: '-4°C',
                          color: AppTheme.success,
                          icon: CupertinoIcons.thermometer,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text('Requires Attention', style: AppTheme.heading2),
                  const SizedBox(height: 16),

                  // Mock "At Risk" List
                  ...Shipment.mockData
                      .where((s) => s.status == ShipmentStatus.atRisk)
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _ShipmentCard(shipment: s),
                        ),
                      ),

                  // Bottom padding for floating navbar
                  const SizedBox(height: 100),
                ],
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
          const SizedBox(height: 12),
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
                      style: AppTheme.caption,
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
            color: CupertinoColors.systemGrey4,
            size: 16,
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
