import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:last_mile_tracker/core/constants/app_constants.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:lmt_models/lmt_models.dart' as models;
import '../../widgets/glass_container.dart';
import '../../widgets/floating_header.dart';
import '../../widgets/empty_state_widget.dart';

class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(recentReadingsProvider);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= AppConstants.tabletBreakpoint;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Content
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 16,
                ),
              ),
              readingsAsync.when(
                data: (readings) {
                  if (readings.isEmpty) {
                    return const SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: CupertinoIcons.doc_text_search,
                        title: 'No Logs Yet',
                        message:
                            'Trips and telemetry data will appear here once recorded.',
                        useGlass: false,
                      ),
                    );
                  }

                  if (isTablet) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: width > 900 ? 3 : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.2,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _LogCard(reading: readings[index]),
                          childCount: readings.length,
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final reading = readings[index];
                      return _LogItem(reading: reading)
                          .animate(delay: (index * 50).ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: 0.1, end: 0);
                    }, childCount: readings.length),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $err')),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final models.SensorReading reading;
  const _LogItem({required this.reading});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      opacity: isDark ? 0.05 : 0.05,
      borderRadius: 16,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('HH:mm:ss').format(reading.timestamp),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? CupertinoColors.white : CupertinoColors.label,
                ),
              ),
              Text(
                DateFormat('MMM d').format(reading.timestamp),
                style: TextStyle(
                  color: isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.secondaryLabel,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          _MiniStat(
            value: '${reading.speed.toStringAsFixed(1)} km/h',
            icon: CupertinoIcons.speedometer,
            color: CupertinoColors.systemCyan,
          ),
          const SizedBox(width: 16),
          _MiniStat(
            value: '${reading.temp.toStringAsFixed(1)}°C',
            icon: CupertinoIcons.thermometer,
            color: CupertinoColors.systemOrange,
          ),
          const SizedBox(width: 16),
          Icon(
            reading.isSynced
                ? CupertinoIcons.cloud_upload_fill
                : CupertinoIcons.cloud_upload,
            size: 16,
            color: reading.isSynced
                ? CupertinoColors.activeGreen
                : CupertinoColors.systemGrey,
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final models.SensorReading reading;
  const _LogCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      opacity: isDark ? 0.05 : 0.08,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('HH:mm:ss').format(reading.timestamp),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Icon(
                reading.isSynced
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.cloud_upload,
                size: 14,
                color: reading.isSynced
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemGrey,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy').format(reading.timestamp),
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(
                value: reading.speed.toStringAsFixed(1),
                icon: CupertinoIcons.speedometer,
                color: CupertinoColors.systemCyan,
              ),
              _MiniStat(
                value: '${reading.temp.toStringAsFixed(1)}°',
                icon: CupertinoIcons.thermometer,
                color: CupertinoColors.systemOrange,
              ),
            ],
          ),
          const FloatingHeader(title: 'Logs'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
