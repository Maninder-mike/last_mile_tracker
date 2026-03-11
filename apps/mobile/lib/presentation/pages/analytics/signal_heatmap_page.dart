import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/fleet_tracker_provider.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

class SignalHeatmapPage extends ConsumerWidget {
  const SignalHeatmapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetTrackers = ref.watch(fleetTrackersProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          fleetTrackers.when(
            data: (trackers) => FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(40.7128, -74.0060),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                CircleLayer(
                  circles: trackers.where((t) => t.latitude != null).map((t) {
                    final color = _getSignalColor(t.rssi);
                    return CircleMarker(
                      point: LatLng(t.lat, t.lon),
                      color: color.withValues(alpha: 0.3),
                      borderStrokeWidth: 0,
                      useRadiusInMeter: true,
                      radius: 20,
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: trackers.where((t) => t.latitude != null).map((t) {
                    return Marker(
                      point: LatLng(t.lat, t.lon),
                      width: 40,
                      height: 40,
                      child: Icon(
                        CupertinoIcons.antenna_radiowaves_left_right,
                        color: _getSignalColor(t.rssi),
                        size: 16,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
          const FloatingHeader(title: 'Signal Heatmap', showBackButton: true),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 40,
      left: 16,
      right: 16,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _legendItem('Strong', AppTheme.success),
            _legendItem('Fair', AppTheme.warning),
            _legendItem('Weak', AppTheme.critical),
            _legendItem('Dead', CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getSignalColor(int? rssi) {
    if (rssi == null) return CupertinoColors.systemGrey;
    if (rssi > -60) return AppTheme.success;
    if (rssi > -80) return AppTheme.warning;
    if (rssi > -100) return AppTheme.critical;
    return CupertinoColors.systemGrey;
  }
}
