import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/domain/services/scorecard_service.dart';
import 'package:fl_chart/fl_chart.dart';

class ScorecardPage extends ConsumerWidget {
  const ScorecardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scorecardAsync = ref.watch(driverScorecardProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
        AppTheme.background,
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        middle: Text('Driver Scorecard', style: AppTheme.heading3),
        backgroundColor: CupertinoDynamicColor.resolve(
          AppTheme.surface,
          context,
        ).withValues(alpha: 0.8),
      ),
      child: SafeArea(
        child: scorecardAsync.when(
          data: (scorecard) => _buildScorecard(context, scorecard),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Failed to load scorecard: $error',
              style: AppTheme.body,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScorecard(BuildContext context, DriverScorecard scorecard) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildOverallScoreSection(context, scorecard.overallScore),
        const SizedBox(height: 24),
        Text('Performance Metrics', style: AppTheme.heading3),
        const SizedBox(height: 16),
        _buildMetricsGrid(context, scorecard),
        const SizedBox(height: 24),
        Text('Recent Activity', style: AppTheme.heading3),
        const SizedBox(height: 16),
        _buildActivityChart(context, scorecard),
      ],
    );
  }

  Widget _buildOverallScoreSection(BuildContext context, double score) {
    final isGood = score >= 80;
    final isWarning = score >= 60 && score < 80;

    final color = isGood
        ? CupertinoColors.activeGreen
        : isWarning
        ? CupertinoColors.systemYellow
        : CupertinoColors.systemRed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(AppTheme.surface, context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Score',
            style: AppTheme.heading3.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Semantics(
              label: 'Overall Safety Score Chart',
              value: '${score.toStringAsFixed(0)} out of 100. $isGood score.',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          value: score,
                          color: color,
                          radius: 15,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: 100 - score,
                          color: CupertinoColors.systemGrey5,
                          radius: 15,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: AppTheme.heading1.copyWith(
                          fontSize: 48,
                          color: color,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: AppTheme.caption.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isGood
                ? 'Excellent Driving!'
                : isWarning
                ? 'Needs Improvement'
                : 'Action Required',
            style: AppTheme.body.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DriverScorecard scorecard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _MetricCard(
          title: 'Hard Braking',
          value: '${scorecard.hardBrakingEvents} pts',
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          iconColor: scorecard.hardBrakingEvents > 0
              ? CupertinoColors.systemRed
              : CupertinoColors.activeGreen,
        ),
        _MetricCard(
          title: 'Speeding',
          value: '${scorecard.speedingEvents} pts',
          icon: CupertinoIcons.speedometer,
          iconColor: scorecard.speedingEvents > 0
              ? CupertinoColors.systemOrange
              : CupertinoColors.activeGreen,
        ),
        _MetricCard(
          title: 'On-Time',
          value: '${scorecard.onTimeDeliveryRate}%',
          icon: CupertinoIcons.clock_fill,
          iconColor: scorecard.onTimeDeliveryRate > 90
              ? CupertinoColors.activeGreen
              : CupertinoColors.systemYellow,
        ),
        _MetricCard(
          title: 'Idle Time',
          value: '${scorecard.idleTimeMinutes}m',
          icon: CupertinoIcons.timer,
          iconColor: scorecard.idleTimeMinutes > 30
              ? CupertinoColors.systemOrange
              : CupertinoColors.activeGreen,
        ),
      ],
    );
  }

  Widget _buildActivityChart(BuildContext context, DriverScorecard scorecard) {
    // A simplified bar chart showing active vs idle time
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(AppTheme.surface, context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Semantics(
        label: 'Active vs Idle Time Bar Chart',
        value:
            '${scorecard.totalActiveMinutes} minutes active, ${scorecard.idleTimeMinutes} minutes idle',
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (scorecard.totalActiveMinutes + scorecard.idleTimeMinutes)
                .toDouble()
                .clamp(10, double.infinity),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    switch (value.toInt()) {
                      case 0:
                        return const Text(
                          'Active',
                          style: TextStyle(fontSize: 10),
                        );
                      case 1:
                        return const Text(
                          'Idle',
                          style: TextStyle(fontSize: 10),
                        );
                      default:
                        return const Text('');
                    }
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: scorecard.totalActiveMinutes.toDouble(),
                    color: CupertinoColors.activeBlue,
                    width: 22,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: scorecard.idleTimeMinutes.toDouble(),
                    color: CupertinoColors.systemGrey,
                    width: 22,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(AppTheme.surface, context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
              Text(
                value,
                style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            title,
            style: AppTheme.caption.copyWith(color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }
}
