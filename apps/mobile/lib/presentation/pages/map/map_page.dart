import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/fleet_tracker_provider.dart';
import 'package:last_mile_tracker/presentation/providers/location_providers.dart';
import 'package:last_mile_tracker/domain/models/fleet_tracker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:last_mile_tracker/core/utils/telemetry_display.dart';
import '../../widgets/floating_header.dart';
import 'widgets/map_cluster_marker.dart';

class LatLngTween extends Tween<LatLng> {
  LatLngTween({super.begin, super.end});

  @override
  LatLng lerp(double t) {
    if (begin == null || end == null) return end ?? const LatLng(0, 0);
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  final _popupController = PopupController();
  bool _isFollowingMode = true;

  @override
  void dispose() {
    _mapController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  void _centerOnUser() async {
    final location = ref.read(userLocationProvider.notifier);
    final success = await location.requestPermission();
    if (success) {
      final pos = ref.read(userLocationProvider).value;
      if (pos != null) {
        _mapController.move(pos, 16.0);
        setState(() => _isFollowingMode = false);
      }
    }
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fleetTrackersAsync = ref.watch(fleetTrackersProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final userPos = userLocationAsync.value;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final urlTemplate = isDark
        ? 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

    // Auto-center on the first critical or nearby tracker if following
    if (_isFollowingMode) {
      fleetTrackersAsync.whenData((trackers) {
        final target = trackers
            .where((t) => t.latitude != null && t.longitude != null)
            .firstOrNull;
        if (target != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(
              LatLng(target.lat, target.lon),
              _mapController.camera.zoom,
            );
          });
        }
      });
    }

    return CupertinoPageScaffold(
      child: PopupScope(
        popupController: _popupController,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(37.7749, -122.4194),
                initialZoom: 15.0,
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture && _isFollowingMode) {
                    setState(() => _isFollowingMode = false);
                  }
                },
                onTap: (tapPosition, point) => _popupController.hideAllPopups(),
              ),
              children: [
                TileLayer(
                  urlTemplate: urlTemplate,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.last_mile_tracker.app',
                ),
                fleetTrackersAsync.when(
                  data: (trackers) {
                    final markers = trackers
                        .where((t) => t.latitude != null && t.longitude != null && t.latitude != 0.0 && t.longitude != 0.0)
                        .map(
                          (t) => Marker(
                            point: LatLng(t.lat, t.lon),
                            width: 60,
                            height: 60,
                            child: _FleetTrackerMarker(tracker: t),
                          ),
                        )
                        .toList();

                    if (userPos != null) {
                      markers.add(
                        Marker(
                          point: userPos,
                          width: 30,
                          height: 30,
                          child: const _UserMarker(),
                        ),
                      );
                    }

                    return MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 45,
                        size: const Size(40, 40),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(50),
                        maxZoom: 15,
                        markers: markers,
                        builder: (context, markers) {
                          return MapClusterMarker(count: markers.length);
                        },
                        popupOptions: PopupOptions(
                          popupController: _popupController,
                          popupBuilder: (context, marker) {
                            if (userPos != null && marker.point == userPos) {
                              return const SizedBox();
                            }
                            final tracker = trackers.firstWhere(
                              (t) =>
                                  t.lat == marker.point.latitude &&
                                  t.lon == marker.point.longitude,
                              orElse: () => trackers.first,
                            );
                            return _FleetTrackerPopup(tracker: tracker);
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ],
            ),

            // Map Controls
            Positioned(
              bottom: 180,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapControlButton(
                    icon: CupertinoIcons.plus,
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: CupertinoIcons.minus,
                    onPressed: _zoomOut,
                  ),
                  const SizedBox(height: 16),
                  _MapControlButton(
                    icon: CupertinoIcons.location_fill,
                    onPressed: _centerOnUser,
                  ),
                ],
              ),
            ),

            const FloatingHeader(title: 'Live Map'),
          ],
        ),
      ),
    );
  }
}

class _FleetTrackerMarker extends StatelessWidget {
  final FleetTracker tracker;
  const _FleetTrackerMarker({required this.tracker});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final isCritical =
        tracker.status == 'critical' || (tracker.batteryLevel ?? 100) < 15;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isCritical)
          Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.critical.withValues(alpha: 0.2),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.4, 1.4),
                duration: 1.5.seconds,
                curve: Curves.easeOut,
              )
              .fadeOut(),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: statusColor, width: 2),
          ),
          child: Icon(
            tracker.isInRange
                ? CupertinoIcons.wifi
                : CupertinoIcons.location_solid,
            size: 14,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (tracker.status == 'critical') return AppTheme.critical;
    if (tracker.status == 'warning') return AppTheme.warning;
    return tracker.isInRange
        ? AppTheme.success
        : CupertinoTheme.of(context).primaryColor;
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBlue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _FleetTrackerPopup extends StatelessWidget {
  final FleetTracker tracker;
  const _FleetTrackerPopup({required this.tracker});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tracker.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildBatteryIcon(),
            ],
          ),
          if (tracker.trackingNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'ID: ${tracker.trackingNumber}',
                style: const TextStyle(
                  fontSize: 10,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          const SizedBox(height: 8),
          _PopupRow(
            label: 'Temp',
            value: '${tracker.temp?.toStringAsFixed(1) ?? "--"}°C',
          ),
          _PopupRow(label: 'Signal', value: TelemetryDisplay.signalLabel(tracker.rssi)),
          _PopupRow(label: 'Last Seen', value: _formatTime(tracker.lastSeen)),
        ],
      ),
    );
  }

  Widget _buildBatteryIcon() {
    final level = tracker.batteryLevel ?? 0;
    final color = level < 20 ? AppTheme.critical : AppTheme.success;
    return Row(
      children: [
        Icon(CupertinoIcons.battery_100, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          '${level.toInt()}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _PopupRow extends StatelessWidget {
  final String label;
  final String value;
  const _PopupRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CupertinoColors.systemGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _MapControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.barBackgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: theme.primaryColor),
      ),
    );
  }
}
