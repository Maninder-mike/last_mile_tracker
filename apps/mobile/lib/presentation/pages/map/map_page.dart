import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/presentation/providers/location_providers.dart';
import 'package:lmt_models/lmt_models.dart' as models;
import '../../widgets/floating_header.dart';
import 'widgets/telemetry_overlay.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with TickerProviderStateMixin {
  late final _mapController = AnimatedMapController(vsync: this);
  final _popupController = PopupController();
  bool _isFollowingMode = true;

  @override
  void dispose() {
    _mapController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  void _recenter(LatLng point) {
    _mapController.animateTo(dest: point, zoom: 16.0);
    setState(() => _isFollowingMode = true);
  }

  void _centerOnUser() async {
    final location = ref.read(userLocationProvider.notifier);
    final success = await location.requestPermission();
    if (success) {
      final pos = ref.read(userLocationProvider).value;
      if (pos != null) {
        _mapController.animateTo(dest: pos, zoom: 16.0);
        setState(() => _isFollowingMode = false);
      }
    }
  }

  void _zoomIn() {
    _mapController.animateTo(
      zoom: _mapController.mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.animateTo(
      zoom: _mapController.mapController.camera.zoom - 1,
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

    const defaultCenter = LatLng(37.7749, -122.4194);
    final readingData = readingAsync.asData?.value;
    final pathData = pathAsync.asData?.value;

    final currentPoint = readingData != null
        ? LatLng(readingData.lat, readingData.lon)
        : defaultCenter;

    // Auto-center in following mode
    if (_isFollowingMode && readingData != null) {
      _mapController.animateTo(dest: currentPoint);
    }

    final userLocationAsync = ref.watch(userLocationProvider);
    final userPos = userLocationAsync.value;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController.mapController,
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
                      color: CupertinoColors.activeBlue.withValues(alpha: 0.6),
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  popupController: _popupController,
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
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (context, marker) =>
                        _MarkerPopup(reading: readingData!),
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
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            onEnd: () {},
            builder: (context, value, child) {
              return Container(
                width: 60 * value,
                height: 60 * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.activeBlue.withValues(
                    alpha: 0.3 * (1 - value),
                  ),
                ),
              );
            },
          ),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: CupertinoColors.white,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: const BoxDecoration(
              color: CupertinoColors.activeBlue,
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

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active
              ? CupertinoColors.activeBlue
              : CupertinoTheme.of(context).barBackgroundColor,
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
          size: 20,
          color: active
              ? CupertinoColors.white
              : (isDark ? CupertinoColors.white : CupertinoColors.activeBlue),
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
