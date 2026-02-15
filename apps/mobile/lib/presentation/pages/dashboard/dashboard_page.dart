import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:last_mile_tracker/core/constants/app_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import '../../widgets/speedometer.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/floating_header.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/connectivity_indicator.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingAsync = ref.watch(latestReadingProvider);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= AppConstants.tabletBreakpoint;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 100,
            ),
            child: Column(
              children: [
                const SizedBox(height: 80),

                // Speedometer Section
                readingAsync.when(
                  data: (reading) {
                    final speed = reading?.speed ?? 0.0;
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 400 : double.infinity,
                        ),
                        child: RepaintBoundary(
                          child: Speedometer(speed: speed, maxSpeed: 100),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 200,
                    child: CupertinoActivityIndicator(),
                  ),
                  error: (error, stackTrace) => const SizedBox(
                    height: 200,
                    child: Icon(CupertinoIcons.exclamationmark_triangle),
                  ),
                ),

                const SizedBox(height: 40),

                readingAsync.when(
                  data: (reading) {
                    if (reading == null) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: EmptyStateWidget(
                          icon: CupertinoIcons.device_laptop,
                          title: 'Ready to Connect',
                          message:
                              'Scan for devices to start receiving telemetry data.',
                          useGlass: true,
                        ),
                      );
                    }

                    final children = [
                      StatCard(
                        title: 'Temperature',
                        value: '${reading.temp.toStringAsFixed(1)} °C',
                        icon: CupertinoIcons.thermometer,
                        color: CupertinoColors.systemOrange,
                      ),
                      const SizedBox(height: 16),
                      StatCard(
                        title: 'Shock',
                        value: '${reading.shockValue}',
                        icon: CupertinoIcons.waveform_circle_fill,
                        color: (reading.shockValue) > 100
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGreen,
                      ),
                    ];

                    return Column(
                      children: children
                          .animate(interval: 100.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const FloatingHeader(
            title: 'Dashboard',
            trailing: ConnectivityIndicator(),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      color: AppTheme.surfaceGlass,
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.heading1.copyWith(letterSpacing: -1.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
