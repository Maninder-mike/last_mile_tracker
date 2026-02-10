import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:last_mile_tracker/core/constants/app_constants.dart';
import 'package:last_mile_tracker/presentation/providers/providers.dart';
import '../../widgets/connection_status_icon.dart';
import '../../widgets/glass_container.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingAsync = ref.watch(latestReadingProvider);
    final pathAsync = ref.watch(recentPathProvider);
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= AppConstants.tabletBreakpoint;

    // Default location (SF)
    const defaultCenter = LatLng(37.7749, -122.4194);

    final center = readingAsync.value != null
        ? LatLng(readingAsync.value!.lat, readingAsync.value!.lon)
        : defaultCenter;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Full Screen Map
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 15.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.last_mile_tracker',
              ),
              if (pathAsync.hasValue && pathAsync.value!.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pathAsync.value!
                          .map((e) => LatLng(e.lat, e.lon))
                          .toList(),
                      color: CupertinoColors.systemBlue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              if (readingAsync.hasValue && readingAsync.value != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        readingAsync.value!.lat,
                        readingAsync.value!.lon,
                      ),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        CupertinoIcons.location_solid,
                        color: CupertinoColors.systemRed,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
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
                          'Live Map',
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

          // Responsive Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: isTablet ? null : 16,
            child: _buildInfoPanel(
              isTablet,
              readingAsync.value,
            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(bool isTablet, dynamic reading) {
    final speed = reading?.speed ?? 0.0;
    final temp = reading?.temp ?? 0.0;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      opacity: 0.1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OverlayStat(
            value: speed.toStringAsFixed(1),
            unit: 'km/h',
            icon: CupertinoIcons.speedometer,
            color: CupertinoColors.systemCyan,
          ),
          if (isTablet) ...[
            const SizedBox(width: 24),
            _OverlayStat(
              value: temp.toStringAsFixed(1),
              unit: '°C',
              icon: CupertinoIcons.thermometer,
              color: CupertinoColors.systemOrange,
            ),
            const SizedBox(width: 24),
            Icon(
              reading?.isSynced == true
                  ? CupertinoIcons.checkmark_seal_fill
                  : CupertinoIcons.cloud_upload,
              size: 20,
              color: reading?.isSynced == true
                  ? CupertinoColors.activeGreen
                  : CupertinoColors.systemGrey,
            ),
          ],
        ],
      ),
    );
  }
}

class _OverlayStat extends StatelessWidget {
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _OverlayStat({
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
