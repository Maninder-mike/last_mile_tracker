import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';

class TelemetryOverlay extends ConsumerWidget {
  const TelemetryOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingAsync = ref.watch(latestReadingProvider);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return readingAsync.when(
      data: (reading) {
        if (reading == null) return const SizedBox.shrink();

        return Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      (isDark ? CupertinoColors.black : CupertinoColors.white)
                          .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        (isDark ? CupertinoColors.white : CupertinoColors.black)
                            .withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: CupertinoIcons.speedometer,
                      label: 'Speed',
                      value: '${reading.speed.toStringAsFixed(1)} km/h',
                      color: CupertinoColors.activeBlue,
                    ),
                    _StatItem(
                      icon: CupertinoIcons.battery_100,
                      label: 'Battery',
                      value: '${reading.batteryLevel.toInt()}%',
                      color: reading.batteryLevel > 20
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemRed,
                    ),
                    _StatItem(
                      icon: CupertinoIcons.antenna_radiowaves_left_right,
                      label: 'RSSI',
                      value: '${reading.rssi} dBm',
                      color: CupertinoColors.systemOrange,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}
