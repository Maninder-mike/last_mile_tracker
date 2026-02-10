import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/database/app_database.dart';
import '../../../data/services/ble_service.dart';
import '../../providers/providers.dart';
import '../../../core/utils/file_logger.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/floating_header.dart';
import 'connectivity_page.dart';
import 'widgets/firmware_update_tile.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSyncing = false;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final bleService = ref.watch(bleServiceProvider);
    final latestReading = ref.watch(latestReadingProvider).value;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              bottom: 100,
            ),
            children: [
              _buildHeroScanner(
                bleService,
                latestReading,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              CupertinoListSection.insetGrouped(
                header: const Text('Connectivity'),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  _SettingsTile(
                    title: 'Bluetooth & WiFi',
                    subtitle: 'Configure device communication',
                    icon: CupertinoIcons.bluetooth,
                    iconColor: CupertinoColors.activeBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const ConnectivityPage(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    title: 'Cloud Sync',
                    subtitle: 'Sync telemetry to fleet portal',
                    icon: CupertinoIcons.cloud_upload,
                    iconColor: CupertinoColors.systemIndigo,
                    trailing: _isSyncing
                        ? const CupertinoActivityIndicator(radius: 8)
                        : const Icon(
                            CupertinoIcons.chevron_right,
                            size: 18,
                            color: CupertinoColors.systemGrey,
                          ),
                    onTap: _isSyncing
                        ? null
                        : () async {
                            setState(() => _isSyncing = true);
                            await ref.read(syncManagerProvider).syncData();
                            if (mounted) setState(() => _isSyncing = false);
                          },
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                header: const Text('Data Management'),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  _SettingsTile(
                    title: 'Export Logs',
                    subtitle: 'Download trip history as text',
                    icon: CupertinoIcons.doc_text,
                    iconColor: CupertinoColors.systemGreen,
                    trailing: _isExporting
                        ? const CupertinoActivityIndicator(radius: 8)
                        : const Icon(
                            CupertinoIcons.chevron_right,
                            size: 18,
                            color: CupertinoColors.systemGrey,
                          ),
                    onTap: _isExporting
                        ? null
                        : () async {
                            setState(() => _isExporting = true);
                            final logs = await FileLogger.getLogs();
                            if (!mounted) return;

                            if (logs == "No logs found.") {
                              _showAlert(
                                'No Logs',
                                'There are no logs to export yet.',
                              );
                              setState(() => _isExporting = false);
                              return;
                            }

                            final dir =
                                await getApplicationDocumentsDirectory();
                            final file = File('${dir.path}/app_logs.txt');
                            if (await file.exists()) {
                              // Share.shareXFiles is the correct API in share_plus 10.x
                              await Share.shareXFiles([
                                XFile(file.path),
                              ], text: 'Last Mile Tracker Logs');
                            }
                            setState(() => _isExporting = false);
                          },
                  ),
                  _SettingsTile(
                    title: 'Clear Local Database',
                    subtitle: 'Wipe all cached sensor data',
                    icon: CupertinoIcons.trash,
                    iconColor: CupertinoColors.destructiveRed,
                    onTap: () => _showDeleteConfirmation(),
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                header: const Text('Device Tools'),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  _SettingsTile(
                    title: 'Simulator Mode',
                    subtitle: 'Generate mock telemetry data',
                    icon: CupertinoIcons.lab_flask,
                    iconColor: CupertinoColors.systemPurple,
                    trailing: CupertinoSwitch(
                      value: bleService.simulationActive,
                      onChanged: (v) =>
                          setState(() => bleService.toggleSimulation()),
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final otaService = ref.watch(otaServiceProvider);
                      return _SettingsTile(
                        title: 'Auto-Check Updates',
                        subtitle: 'Check for firmware on startup',
                        icon: CupertinoIcons.arrow_2_circlepath,
                        iconColor: CupertinoColors.systemOrange,
                        trailing: CupertinoSwitch(
                          value: otaService.currentState.isAutoCheckEnabled,
                          onChanged: (v) => otaService.toggleAutoCheck(v),
                        ),
                      );
                    },
                  ),
                  const FirmwareUpdateTile(),
                ],
              ),

              CupertinoListSection.insetGrouped(
                header: const Text('Support & Legal'),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _SettingsTile(
                    title: 'Help Center',
                    icon: CupertinoIcons.question_circle,
                    iconColor: CupertinoColors.systemGrey,
                    onTap: () {},
                  ),
                  _SettingsTile(
                    title: 'Privacy Policy',
                    icon: CupertinoIcons.shield,
                    iconColor: CupertinoColors.systemGrey,
                    onTap: () {},
                  ),
                  _SettingsTile(
                    title: 'Terms of Service',
                    icon: CupertinoIcons.doc_plaintext,
                    iconColor: CupertinoColors.systemGrey,
                    onTap: () {},
                  ),
                ],
              ),

              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Text(
                    'Last Mile Tracker v1.2.0\nBuild #20260210',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CupertinoColors.systemGrey2,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating Header
          const FloatingHeader(title: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildHeroScanner(BleService bleService, SensorReading? latest) {
    final isConnected =
        bleService.lastState == BluetoothConnectionState.connected;

    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      opacity: isDark ? 0.05 : 0.08,
      borderRadius: 24,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (isConnected
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.systemRed)
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.antenna_radiowaves_left_right,
                  color: isConnected
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Tracker Online' : 'Tracker Offline',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.label,
                      ),
                    ),
                    Text(
                      isConnected
                          ? 'Firmware v1.0.4'
                          : 'Searching for device...',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isConnected && latest != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                height: 0.5,
                color: isDark
                    ? CupertinoColors.systemGrey.withValues(alpha: 0.3)
                    : CupertinoColors.systemGrey5,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeroStat(
                  label: 'Temp',
                  value: '${latest.temp.toStringAsFixed(1)}°C',
                ),
                _HeroStat(label: 'Signal', value: '${latest.rssi ?? -60} dBm'),
                _HeroStat(
                  label: 'Battery',
                  value: '${latest.batteryLevel.toStringAsFixed(1)}V',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAlert(String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear Database'),
        content: const Text(
          'This will delete all stored sensor data. This action is irreversible.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(sensorDaoProvider).deleteAllReadings();
              Navigator.pop(ctx);
            },
            child: const Text('Delete All'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CupertinoListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? CupertinoColors.white : CupertinoColors.label,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.secondaryLabel,
              ),
            )
          : null,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: isDark ? 0.2 : 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.systemGrey2,
                )
              : null),
      onTap: onTap,
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
