import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/analytics_providers.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/presentation/widgets/entrance_animation.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentStats = ref.watch(shipmentStatsProvider);
    final healthStats = ref.watch(deviceHealthStatsProvider);
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              bottom: 100,
              left: 16,
              right: 16,
            ),
            children: [
              EntranceAnimation(
                index: 0,
                child: _buildShipmentDistributionChart(context, shipmentStats),
              ),
              const SizedBox(height: 24),
              EntranceAnimation(
                index: 1,
                child: _buildBatteryHealthChart(
                  context,
                  healthStats,
                  primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              EntranceAnimation(
                index: 2,
                child: _buildSummaryMetrics(shipmentStats, healthStats),
              ),
            ],
          ),
          const FloatingHeader(title: 'Analytics Trends', showBackButton: true),
        ],
      ),
    );
  }

  Widget _buildShipmentDistributionChart(
    BuildContext context,
    ShipmentStats stats,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipment Status', style: AppTheme.heading2),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: stats.inTransit.toDouble(),
                    color: CupertinoTheme.of(context).primaryColor,
                    title: 'In Transit',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: stats.delivered.toDouble(),
                    color: AppTheme.success,
                    title: 'Delivered',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: stats.atRisk.toDouble(),
                    color: AppTheme.critical,
                    title: 'At Risk',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLegendItem(
            'In Transit',
            CupertinoTheme.of(context).primaryColor,
          ),
          _buildLegendItem('Delivered', AppTheme.success),
          _buildLegendItem('At Risk', AppTheme.critical),
        ],
      ),
    );
  }

  Widget _buildBatteryHealthChart(
    BuildContext context,
    DeviceHealthStats stats,
    Color primary,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fleet Battery Health', style: AppTheme.heading2),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: stats.batteryLevels.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: e.value < 20 ? AppTheme.critical : primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${stats.lowBattery} devices require immediate charging',
            style: AppTheme.caption.copyWith(
              color: stats.lowBattery > 0
                  ? AppTheme.critical
                  : AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(ShipmentStats sStats, DeviceHealthStats hStats) {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${(sStats.delivered / sStats.total * 100).toInt()}%',
                  style: AppTheme.heading1,
                ),
                const Text('Delivery Rate', style: AppTheme.caption),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('${hStats.totalDevices}', style: AppTheme.heading1),
                const Text('Active Units', style: AppTheme.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTheme.body),
        ],
      ),
    );
  }
}
