import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceDetailPage extends ConsumerWidget {
  final String deviceId;
  final String initialName;

  const DeviceDetailPage({
    super.key,
    required this.deviceId,
    required this.initialName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerAsync = ref.watch(trackerProvider(deviceId));
    final connectionState =
        ref.watch(bleConnectionStateProvider).value ??
        BluetoothConnectionState.disconnected;
    final bleService = ref.watch(bleServiceProvider);

    // Check if this device is the one currently connected
    final connectedDevice = bleService.connectedDevice;
    final isThisDeviceConnected =
        connectedDevice?.remoteId.str == deviceId &&
        connectionState == BluetoothConnectionState.connected;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          // Background Glow / decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 120)),

              // Device Info Header
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: trackerAsync.when(
                    data: (tracker) => _DeviceHeader(
                      name: tracker?.name ?? initialName,
                      id: deviceId,
                      lastSeen: tracker?.lastSeen,
                      isConnected: isThisDeviceConnected,
                    ),
                    loading: () => _DeviceHeader(
                      name: initialName,
                      id: deviceId,
                      isConnected: isThisDeviceConnected,
                    ),
                    error: (_, _) => _DeviceHeader(
                      name: initialName,
                      id: deviceId,
                      isConnected: isThisDeviceConnected,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Telemetry Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: trackerAsync.when(
                  data: (tracker) => SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _TelemetryModule(
                        title: 'Battery',
                        value:
                            '${tracker?.batteryLevel?.toStringAsFixed(0) ?? "--"}%',
                        icon: CupertinoIcons.battery_100,
                        color: (tracker?.batteryLevel ?? 0) < 20
                            ? AppTheme.warning
                            : AppTheme.success,
                        subtitle: 'Charge Level',
                      ),
                      _TelemetryModule(
                        title: 'Temperature',
                        value: '${tracker?.temp?.toStringAsFixed(1) ?? "--"}°C',
                        icon: CupertinoIcons.thermometer,
                        color: (tracker?.temp ?? 0) > 30
                            ? AppTheme.warning
                            : AppTheme.primary,
                        subtitle:
                            tracker?.additionalTemps != null &&
                                tracker!.additionalTemps!.isNotEmpty
                            ? 'Core (Aux: ${tracker.additionalTemps})'
                            : 'Core Temp',
                      ),
                      _TelemetryModule(
                        title: 'Shock',
                        value: tracker?.shockValue != null
                            ? '${tracker!.shockValue}G'
                            : '--',
                        icon: CupertinoIcons.wind,
                        color: (tracker?.shockValue ?? 0) > 2
                            ? AppTheme.warning
                            : AppTheme.primary,
                        subtitle: 'Impact Force',
                      ),
                      _TelemetryModule(
                        title: 'Signal',
                        value:
                            '-- dBm', // We don't have live RSSI in Tracker table yet
                        icon: CupertinoIcons.antenna_radiowaves_left_right,
                        color: AppTheme.textSecondary,
                        subtitle: 'RSSI',
                      ),
                      _TelemetryModule(
                        title: 'Health',
                        value: tracker?.batteryDrop != null
                            ? '${tracker!.batteryDrop!.toStringAsFixed(0)}mV'
                            : '--',
                        icon: CupertinoIcons.heart_fill,
                        color: (tracker?.batteryDrop ?? 0) > 150
                            ? AppTheme.critical
                            : AppTheme.success,
                        subtitle: 'Battery Drop',
                      ),
                    ],
                  ),
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(child: Text('Error loading telemetry: $e')),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Location Module
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: trackerAsync.when(
                    data: (tracker) =>
                        _LocationModule(lat: tracker?.lat, lng: tracker?.lon),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Actions Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remote Actions',
                        style: AppTheme.heading2.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      _ActionButton(
                        title: 'Identify Device',
                        subtitle: 'Flash LEDs and beep buzzer',
                        icon: CupertinoIcons.lightbulb_fill,
                        onTap: isThisDeviceConnected
                            ? () => bleService.identifyDevice()
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        title: 'Reboot Device',
                        subtitle: 'Perform a soft system reset',
                        icon: CupertinoIcons.restart,
                        onTap: isThisDeviceConnected
                            ? () => bleService.rebootDevice()
                            : null,
                        isDestructive: true,
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        title: 'Reset WiFi Config',
                        subtitle: 'Clear saved credentials',
                        icon: CupertinoIcons.wifi_exclamationmark,
                        onTap: isThisDeviceConnected
                            ? () => bleService.resetWifiConfig()
                            : null,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          FloatingHeader(
            title: 'Device Details',
            showBackButton: true,
            trailing: isThisDeviceConnected
                ? const _ActivePulse()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _LocationModule extends StatelessWidget {
  final double? lat;
  final double? lng;

  const _LocationModule({this.lat, this.lng});

  Future<void> _openInMaps(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      return GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                CupertinoIcons.location_slash,
                color: AppTheme.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text('Location Unavailable', style: AppTheme.body),
              Text('No GPS signal received yet', style: AppTheme.caption),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Live Location',
            style: AppTheme.heading2.copyWith(fontSize: 18),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 200,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat!, lng!),
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.lastmile.tracker',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat!, lng!),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.surface,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.location_fill,
                              color: AppTheme.surface,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: AppTheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => _openInMaps(lat!, lng!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.map,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Open Maps',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        '${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}',
                        style: AppTheme.caption.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  final String name;
  final String id;
  final DateTime? lastSeen;
  final bool isConnected;

  const _DeviceHeader({
    required this.name,
    required this.id,
    this.lastSeen,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    final lastSeenStr = lastSeen != null
        ? 'Last seen ${DateFormat('MMM d, HH:mm').format(lastSeen!)}'
        : 'Never seen';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isConnected
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      (isConnected ? AppTheme.success : AppTheme.textSecondary)
                          .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'CONNECTED' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isConnected
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(name, style: AppTheme.heading1),
        const SizedBox(height: 4),
        Text(
          id,
          style: AppTheme.caption.copyWith(
            fontFamily: 'monospace',
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(lastSeenStr, style: AppTheme.caption),
      ],
    );
  }
}

class _TelemetryModule extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TelemetryModule({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  title,
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.heading2.copyWith(color: color, fontSize: 24),
                ),
                Text(subtitle, style: AppTheme.caption.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final color = isDestructive ? AppTheme.critical : AppTheme.primary;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: GlassContainer(
        opacity: isDisabled ? 0.05 : 0.1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDisabled ? 0.05 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDisabled ? AppTheme.textSecondary : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? AppTheme.textSecondary : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!isDisabled)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePulse extends StatefulWidget {
  const _ActivePulse();

  @override
  State<_ActivePulse> createState() => _ActivePulseState();
}

class _ActivePulseState extends State<_ActivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.success,
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withValues(
                  alpha: 1 - _controller.value,
                ),
                blurRadius: 8 * _controller.value,
                spreadRadius: 4 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
