import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/core/constants/app_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../widgets/speedometer.dart';
import '../../widgets/connection_status_icon.dart';
import '../../widgets/glass_container.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingAsync = ref.watch(latestReadingProvider);
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= AppConstants.tabletBreakpoint;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              bottom: 100,
            ),
            child: Column(
              children: [
                _buildConnectionStatus(ref)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.2, end: 0),
                const SizedBox(height: 32),

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
                  error: (_, __) => const SizedBox(
                    height: 200,
                    child: Icon(CupertinoIcons.exclamationmark_triangle),
                  ),
                ),

                const SizedBox(height: 40),

                readingAsync.when(
                  data: (reading) {
                    final children = [
                      StatCard(
                        title: 'Temperature',
                        value: reading != null
                            ? '${reading.temp.toStringAsFixed(1)} °C'
                            : '---',
                        icon: CupertinoIcons.thermometer,
                        color: CupertinoColors.systemOrange,
                      ),
                      const SizedBox(height: 16),
                      StatCard(
                        title: 'Shock',
                        value: reading != null
                            ? '${reading.shockValue}'
                            : '---',
                        icon: CupertinoIcons.waveform_circle_fill,
                        color: (reading?.shockValue ?? 0) > 100
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
                  error: (err, _) => Text('Error: $err'),
                ),
              ],
            ),
          ),

          // Custom Glass Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassContainer(
              padding: const EdgeInsets.only(bottom: 12),
              borderRadius: 0,
              opacity: 0.1,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.1)
                      : CupertinoColors.black.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                        const Positioned(
                          right: 0,
                          child: ConnectionStatusIcon(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(WidgetRef ref) {
    final connectionState = ref.watch(bleConnectionStateProvider);
    final bleService = ref.watch(bleServiceProvider);

    return connectionState.when(
      data: (state) {
        final isConnected = state == BluetoothConnectionState.connected;

        if (!isConnected && bleService.isScanning) {
          return GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 20,
            opacity: 0.05,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(radius: 8),
                SizedBox(width: 8),
                Text(
                  'Searching for device...',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          );
        }

        return GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: 20,
          opacity: 0.1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.xmark_circle_fill,
                color: isConnected
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isConnected
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (err, _) => Text('Error: $err'),
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
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      opacity: isDark ? 0.05 : 0.08,
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
                  style: TextStyle(
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.secondaryLabel,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.label,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
