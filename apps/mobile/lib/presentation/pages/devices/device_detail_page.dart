import 'dart:convert';
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
import 'package:last_mile_tracker/core/constants/ble_constants.dart';
import 'package:last_mile_tracker/data/services/ble_service.dart';
import 'package:last_mile_tracker/data/services/ota_service.dart';
import 'package:last_mile_tracker/presentation/providers/ota_providers.dart';
import 'package:last_mile_tracker/presentation/providers/service_providers.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DeviceDetailPage extends ConsumerStatefulWidget {
  final String deviceId;
  final String name;

  const DeviceDetailPage({
    super.key,
    required this.deviceId,
    required this.name,
  });

  @override
  ConsumerState<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends ConsumerState<DeviceDetailPage> {
  @override
  Widget build(BuildContext context) {
    final connectionStateAsync = ref.watch(bleConnectionStateProvider);
    final isConnected = connectionStateAsync.when(
      data: (state) => state == BluetoothConnectionState.connected,
      loading: () => false,
      error: (err, stack) => false,
    );

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _DeviceHeader(
                    deviceId: widget.deviceId,
                    name: widget.name,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _UpdateBanner(deviceId: widget.deviceId),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Telemetry Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _BatteryModule(
                              key: ValueKey('bat_${widget.deviceId}'),
                              deviceId: widget.deviceId,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _TempModule(
                              key: ValueKey('temp_${widget.deviceId}'),
                              deviceId: widget.deviceId,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ShockModule(
                              key: ValueKey('shock_${widget.deviceId}'),
                              deviceId: widget.deviceId,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LiveSignalModule(
                              key: ValueKey('signal_${widget.deviceId}'),
                              deviceId: widget.deviceId,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _HealthModule(
                        key: ValueKey('health_${widget.deviceId}'),
                        deviceId: widget.deviceId,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Location Module
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _LocationModule(deviceId: widget.deviceId),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Device Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _DeviceActions(deviceId: widget.deviceId),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingHeader(title: widget.name, showBackButton: true),
          ),
          // Connection Status Overlay
          if (!isConnected)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: GlassContainer(
                color: AppTheme.critical.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        color: AppTheme.critical,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Disconnected',
                              style: AppTheme.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.critical,
                              ),
                            ),
                            Text(
                              'Reconnect to send commands or view live signal.',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 1, end: 0),
            ),
        ],
      ),
    );
  }

  static Color getSignalColor(int rssi) {
    if (rssi > -60) return AppTheme.success;
    if (rssi > -80) return AppTheme.warning;
    return AppTheme.critical;
  }
}

class _BatteryModule extends ConsumerWidget {
  final String deviceId;
  const _BatteryModule({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bat = ref.watch(
      trackerProvider(deviceId).select((t) => t.value?.batteryLevel),
    );

    final isUsbPowered = bat != null && bat < 1.0;
    return _TelemetryModule(
          title: 'BATTERY',
          value: isUsbPowered ? 'USB' : '${bat?.toStringAsFixed(0) ?? "--"}%',
          icon: isUsbPowered
              ? CupertinoIcons.bolt_fill
              : CupertinoIcons.battery_100,
          color: isUsbPowered
              ? AppTheme.primary
              : (bat ?? 0) < 20
              ? AppTheme.warning
              : AppTheme.success,
          subtitle: isUsbPowered ? 'Wired Power' : 'Charge Level',
        )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}

class _TempModule extends ConsumerWidget {
  final String deviceId;
  const _TempModule({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temp = ref.watch(
      trackerProvider(deviceId).select((t) => t.value?.temp),
    );
    final additionalTemps = ref.watch(
      trackerProvider(deviceId).select((t) => t.value?.additionalTemps),
    );

    return _TelemetryModule(
          title: 'TEMPERATURE',
          value: '${temp?.toStringAsFixed(1) ?? "--"}°C',
          icon: CupertinoIcons.thermometer,
          color: (temp ?? 0) > 30 ? AppTheme.warning : AppTheme.primary,
          subtitle: _getTempSubtitle(additionalTemps),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  String _getTempSubtitle(String? additional) {
    if (additional == null || additional.isEmpty) return 'Core Temp';
    try {
      final Map<String, dynamic> extras = jsonDecode(additional);
      if (extras.containsKey('T2')) return 'Core (Aux: ${extras['T2']}°)';
      return 'Core (Aux: ${extras.values.first}°)';
    } catch (_) {
      return 'Core Temp';
    }
  }
}

class _ShockModule extends ConsumerWidget {
  final String deviceId;
  const _ShockModule({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shock = ref.watch(
      trackerProvider(deviceId).select((t) => t.value?.shockValue),
    );

    return _TelemetryModule(
          title: 'SHOCK',
          value: shock != null ? '${shock}G' : '--',
          icon: CupertinoIcons.wind,
          color: (shock ?? 0) > 2 ? AppTheme.warning : AppTheme.primary,
          subtitle: 'Impact Force',
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}

class _LiveSignalModule extends ConsumerWidget {
  final String deviceId;
  const _LiveSignalModule({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rssi = ref.watch(
      bleScanResultsProvider.select((results) {
        final tracker = results.value?.firstWhereOrNull(
          (t) => t.id == deviceId,
        );
        return tracker?.rssi;
      }),
    );

    return _TelemetryModule(
      title: 'SIGNAL',
      value: rssi != null ? '$rssi dBm' : '-- dBm',
      icon: CupertinoIcons.antenna_radiowaves_left_right,
      color: _DeviceDetailPageState.getSignalColor(rssi ?? -100),
      subtitle: 'RSSI (Live)',
    );
  }
}

class _HealthModule extends ConsumerWidget {
  final String deviceId;
  const _HealthModule({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drop = ref.watch(
      trackerProvider(deviceId).select((t) => t.value?.batteryDrop),
    );

    return _TelemetryModule(
          title: 'HEALTH',
          value: drop != null ? '${drop.toStringAsFixed(0)}mV' : '--',
          icon: CupertinoIcons.heart_fill,
          color: (drop ?? 0) > 150 ? AppTheme.critical : AppTheme.success,
          subtitle: (drop ?? 0) < 100 ? 'Healthy' : 'Check Battery',
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}

class _DeviceHeader extends ConsumerWidget {
  final String deviceId;
  final String name;

  const _DeviceHeader({required this.deviceId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(bleConnectionStateProvider).value;
    final isConnected = connectionState == BluetoothConnectionState.connected;
    final lastSeen = ref.watch(
      trackerProvider(deviceId).select((t) => t.value?.lastSeen),
    );
    final firmwareVersion = ref.watch(deviceFirmwareVersionProvider).value;

    final lastSeenStr = lastSeen != null
        ? 'Last seen ${DateFormat('MMM d, HH:mm').format(lastSeen)}'
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
                  if (isConnected)
                    const _ActivePulse()
                  else
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'CONNECTED' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isConnected
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 16),
        Text(
              name,
              style: AppTheme.heading1.copyWith(height: 1.1, letterSpacing: -1),
            )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideX(begin: -0.05, end: 0),
        const SizedBox(height: 4),
        Text(
          deviceId.toUpperCase(),
          style: AppTheme.caption.copyWith(
            fontFamily: 'monospace',
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(lastSeenStr, style: AppTheme.caption),
            if (isConnected || firmwareVersion != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.rocket_fill,
                      size: 10,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      firmwareVersion != null
                          ? 'v$firmwareVersion'
                          : 'ESP32 Firmware',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }
}

class _LocationModule extends ConsumerWidget {
  final String deviceId;

  const _LocationModule({required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lat = ref.watch(
      trackerProvider(deviceId).select((t) => t.value?.lat),
    );
    final lng = ref.watch(
      trackerProvider(deviceId).select((t) => t.value?.lon),
    );
    final hasLocation = lat != null && lng != null && lat != 0 && lng != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAST KNOWN LOCATION',
          style: AppTheme.label.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: GlassContainer(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 200,
              child: Stack(
                children: [
                  if (hasLocation)
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 15,
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
                              point: LatLng(lat, lng),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                CupertinoIcons.location_solid,
                                color: AppTheme.primary,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Container(
                      color: AppTheme.shimmerBase.withValues(alpha: 0.1),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.location_slash,
                              color: AppTheme.textSecondary,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No location data available',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (hasLocation)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        onPressed: () async {
                          final url =
                              'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.map, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Open Maps',
                              style: AppTheme.body.copyWith(
                                color: CupertinoColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdateBanner extends ConsumerWidget {
  final String deviceId;
  const _UpdateBanner({required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otaState = ref.watch(otaStateProvider).value;
    if (otaState == null || otaState.status == OtaStatus.idle) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: GlassContainer(
        color: AppTheme.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.cloud_download,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Updating Firmware...',
                          style: AppTheme.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(otaState.message, style: AppTheme.caption),
                      ],
                    ),
                  ),
                  Text(
                    '${(otaState.progress * 100).toStringAsFixed(0)}%',
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  height: 4,
                  width: double.infinity,
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: otaState.progress,
                    child: Container(color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceActions extends ConsumerWidget {
  final String deviceId;
  const _DeviceActions({required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(bleConnectionStateProvider).value;
    final isConnected = connectionState == BluetoothConnectionState.connected;
    final bleService = ref.watch(bleServiceProvider);

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEVICE ACTIONS',
              style: AppTheme.label.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 16),
            _ActionButton(
              title: 'Identify Device',
              subtitle: 'Flash LED and play buzzer',
              icon: CupertinoIcons.light_max,
              onTap: isConnected ? bleService.identifyDevice : null,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              title: 'OTA Update (BLE)',
              subtitle: 'Upload local firmware bundle',
              icon: CupertinoIcons.cloud_upload,
              onTap: isConnected
                  ? () => ref.read(otaServiceProvider).performUpdate(bleService)
                  : null,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              title: 'WiFi OTA Config',
              subtitle: 'Configure background updates',
              icon: CupertinoIcons.wifi,
              onTap: isConnected
                  ? () => _showWiFiOtaDialog(context, ref, bleService)
                  : null,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              title: 'Reboot Device',
              subtitle: 'Safe restart microcontroller',
              icon: CupertinoIcons.restart,
              isDestructive: true,
              onTap: isConnected ? bleService.rebootDevice : null,
            ),
          ],
        )
        .animate()
        .fadeIn(delay: 700.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

void _showWiFiOtaDialog(
  BuildContext pageContext,
  WidgetRef ref,
  BleService bleService,
) {
  final ownerController = TextEditingController(text: BleConstants.githubOwner);
  final repoController = TextEditingController(text: BleConstants.githubRepo);
  final intervalController = TextEditingController(text: '86400');

  showCupertinoDialog(
    context: pageContext,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('WiFi OTA Config'),
      content: Column(
        children: [
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: ownerController,
            placeholder: 'GitHub Owner',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.person, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: repoController,
            placeholder: 'Repository',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.folder, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: intervalController,
            placeholder: 'Interval (seconds)',
            keyboardType: TextInputType.number,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.timer, size: 18),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            final owner = ownerController.text;
            final repo = repoController.text;
            final interval = int.tryParse(intervalController.text) ?? 86400;

            if (owner.isNotEmpty && repo.isNotEmpty) {
              bleService.configureWiFiOta(
                owner: owner,
                repo: repo,
                interval: interval,
              );
              Navigator.pop(dialogContext);
              showCupertinoDialog(
                context: pageContext,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('Command Sent'),
                  content: Text(
                    'WiFi OTA update check configured for $owner/$repo every $interval seconds.',
                    style: AppTheme.body,
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              );
            }
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
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
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 16),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          duration: 1000.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                        ),
                    Text(
                      title,
                      style: AppTheme.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.5,
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
                      style: AppTheme.heading2.copyWith(
                        color: color,
                        fontSize: 26,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
