import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/presentation/providers/location_providers.dart';
import 'package:lmt_models/lmt_models.dart' as models;
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/floating_header.dart';
import 'widgets/telemetry_overlay.dart';
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

  // Animation for marker smoothing
  late AnimationController _markerMoveController;
  late Animation<LatLng> _markerMoveAnimation;
  LatLng _markerPoint = const LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _markerMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _markerMoveAnimation = LatLngTween(begin: _markerPoint, end: _markerPoint)
        .animate(
          CurvedAnimation(
            parent: _markerMoveController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _markerMoveController.addListener(() {
      setState(() {
        _markerPoint = _markerMoveAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _popupController.dispose();
    _markerMoveController.dispose();
    super.dispose();
  }

  void _recenter(LatLng point) {
    _mapController.move(point, 16.0);
    setState(() => _isFollowingMode = true);
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
    final readingAsync = ref.watch(latestReadingProvider);
    final pathAsync = ref.watch(recentPathProvider);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    // CartoDB Tiles (Cleaner than OSM for professional apps)
    final urlTemplate = isDark
        ? 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

    final readingData = readingAsync.asData?.value;
    final pathData = pathAsync.asData?.value;

    // Detect coordinate changes and trigger smoothing animation
    ref.listen<AsyncValue<models.SensorReading?>>(latestReadingProvider, (
      prev,
      next,
    ) {
      if (next.hasValue && next.value != null) {
        final newTarget = LatLng(next.value!.lat, next.value!.lon);
        _markerMoveAnimation = LatLngTween(begin: _markerPoint, end: newTarget)
            .animate(
              CurvedAnimation(
                parent: _markerMoveController,
                curve: Curves.easeOutCubic,
              ),
            );
        _markerMoveController.forward(from: 0);
      }
    });

    final currentPoint = _markerPoint;

    // Auto-center in following mode (smooth camera)
    if (_isFollowingMode && readingData != null) {
      _mapController.move(currentPoint, _mapController.camera.zoom);
    }

    final userLocationAsync = ref.watch(userLocationProvider);
    final userPos = userLocationAsync.value;

    return CupertinoPageScaffold(
      child: PopupScope(
        popupController: _popupController,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPoint,
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
                if (pathData != null && pathData.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: pathData
                            .map((e) => LatLng(e.lat, e.lon))
                            .toList(),
                        color: CupertinoTheme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.6),
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 45,
                    size: const Size(40, 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: 15,
                    markers: [
                      if (readingData != null)
                        Marker(
                          point: currentPoint,
                          width: 60,
                          height: 60,
                          child: _LiveMarker(isFollowing: _isFollowingMode),
                        ),
                      if (userPos != null)
                        Marker(
                          point: userPos,
                          width: 30,
                          height: 30,
                          child: const _UserMarker(),
                        ),
                    ],
                    builder: (context, markers) {
                      return MapClusterMarker(count: markers.length);
                    },
                    popupOptions: PopupOptions(
                      popupController: _popupController,
                      popupBuilder: (context, marker) {
                        if (readingData == null) return const SizedBox();
                        // Only show popup for device marker, not user marker
                        // Simple check: if marker point matches userPos, it's user marker
                        if (userPos != null && marker.point == userPos) {
                          return const SizedBox();
                        }
                        return _MarkerPopup(reading: readingData);
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Telemetry Overlay
            const TelemetryOverlay(),

            // Map Controls Stack
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
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: _isFollowingMode
                        ? CupertinoIcons.scope
                        : CupertinoIcons.scope,
                    active: _isFollowingMode,
                    onPressed: () => _recenter(currentPoint),
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

class _LiveMarker extends StatelessWidget {
  final bool isFollowing;
  const _LiveMarker({required this.isFollowing});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isFollowing)
          Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CupertinoTheme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  color: CupertinoTheme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.2),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1.2, 1.2),
                curve: Curves.easeOut,
                duration: 2.seconds,
              )
              .fadeOut(begin: 0.6, curve: Curves.easeIn, duration: 2.seconds),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: CupertinoColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemGreen,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final theme = CupertinoTheme.of(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44), // Minimum touch target for accessibility
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? theme.primaryColor : theme.barBackgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: AppTheme.iconSizeMedium,
          color: active
              ? CupertinoColors.white
              : (isDark ? CupertinoColors.white : theme.primaryColor),
        ),
      ),
    );
  }
}

class _MarkerPopup extends StatelessWidget {
  final models.SensorReading reading;
  const _MarkerPopup({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Info',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _PopupRow(label: 'Uptime', value: '${reading.uptime}s'),
          _PopupRow(label: 'RSSI', value: '${reading.rssi} dBm'),
          _PopupRow(
            label: 'Voltage',
            value: '${reading.batteryLevel.toStringAsFixed(2)}V',
          ),
          const SizedBox(height: 4),
          Text(
            'Last updated: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 10,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
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
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
