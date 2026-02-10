import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/presentation/providers/service_providers.dart';
import '../../../core/utils/file_logger.dart';
import '../../widgets/floating_header.dart';
import 'connectivity_page.dart';
import 'settings_theme.dart';
import 'widgets/firmware_update_tile.dart';
import 'widgets/hero_scanner_card.dart';
import 'widgets/settings_tile.dart';

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
              HeroScannerCard(
                connectionState: bleService.lastState,
                latestReading: latestReading,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              _buildConnectivitySection(
                bleService.lastState,
                latestReading?.wifiSsid,
              ),
              _buildDataSection(),
              _buildToolsSection(),
              _buildSupportSection(),
              _buildFooter(),
            ],
          ),
          const FloatingHeader(title: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildConnectivitySection(
    BluetoothConnectionState bleState,
    String? wifiSsid,
  ) {
    final isConnected = bleState == BluetoothConnectionState.connected;

    return CupertinoListSection.insetGrouped(
      header: const Text('Connectivity'),
      margin: SettingsTheme.sectionMargin,
      children: [
        SettingsTile(
          title: 'Connectivity',
          subtitle: 'Bluetooth, WiFi & Provisioning',
          icon: CupertinoIcons.antenna_radiowaves_left_right,
          iconColor: CupertinoColors.activeBlue,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.bluetooth,
                size: 14,
                color: isConnected
                    ? CupertinoColors.activeGreen
                    : SettingsTheme.subtitleColor,
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.wifi,
                size: 14,
                color: (wifiSsid != null)
                    ? CupertinoColors.activeGreen
                    : SettingsTheme.subtitleColor,
              ),
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: SettingsTheme.chevronColor,
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ConnectivityPage(),
              ),
            );
          },
        ),
        SettingsTile(
          title: 'Cloud Sync',
          subtitle: 'Sync telemetry to fleet portal',
          icon: CupertinoIcons.cloud_upload,
          iconColor: CupertinoColors.systemIndigo,
          trailing: _isSyncing
              ? const CupertinoActivityIndicator(radius: 8)
              : const Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: SettingsTheme.subtitleColor,
                ),
          onTap: _isSyncing ? null : _handleCloudSync,
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('Data Management'),
      margin: SettingsTheme.sectionMargin,
      children: [
        SettingsTile(
          title: 'Export Logs',
          subtitle: 'Download trip history as text',
          icon: CupertinoIcons.doc_text,
          iconColor: CupertinoColors.systemGreen,
          trailing: _isExporting
              ? const CupertinoActivityIndicator(radius: 8)
              : const Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: SettingsTheme.subtitleColor,
                ),
          onTap: _isExporting ? null : _handleExportLogs,
        ),
        SettingsTile(
          title: 'Clear Local Database',
          subtitle: 'Wipe all cached sensor data',
          icon: CupertinoIcons.trash,
          iconColor: CupertinoColors.destructiveRed,
          onTap: _showDeleteConfirmation,
        ),
      ],
    );
  }

  Widget _buildToolsSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('Device Tools'),
      margin: SettingsTheme.sectionMargin,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final otaService = ref.watch(otaServiceProvider);
            return SettingsTile(
              title: 'Auto-Check Updates',
              subtitle: 'Check for firmware on startup',
              icon: CupertinoIcons.arrow_2_circlepath,
              iconColor: CupertinoColors.systemOrange,
              trailing: CupertinoSwitch(
                value: otaService.currentState.isAutoCheckEnabled,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  otaService.toggleAutoCheck(v);
                },
              ),
              onTap: null,
            );
          },
        ),
        const FirmwareUpdateTile(),
      ],
    );
  }

  Widget _buildSupportSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('Support & Legal'),
      margin: SettingsTheme.sectionMarginBottom,
      children: [
        SettingsTile(
          title: 'Help Center',
          icon: CupertinoIcons.question_circle,
          iconColor: CupertinoColors.systemGrey,
          onTap: () {},
        ),
        SettingsTile(
          title: 'Privacy Policy',
          icon: CupertinoIcons.shield,
          iconColor: CupertinoColors.systemGrey,
          onTap: () {},
        ),
        SettingsTile(
          title: 'Terms of Service',
          icon: CupertinoIcons.doc_plaintext,
          iconColor: CupertinoColors.systemGrey,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: ref
            .watch(packageInfoProvider)
            .when(
              data: (info) => Text(
                'Last Mile Tracker v${info.version}\nBuild #${info.buildNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SettingsTheme.chevronColor,
                  fontSize: SettingsTheme.versionNumberSize,
                ),
              ),
              loading: () => const CupertinoActivityIndicator(radius: 8),
              error: (_, __) => const Text('vUnknown'),
            ),
      ),
    );
  }

  Future<void> _handleCloudSync() async {
    HapticFeedback.selectionClick();
    setState(() => _isSyncing = true);
    await ref.read(syncManagerProvider).syncData();
    if (mounted) {
      setState(() => _isSyncing = false);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _handleExportLogs() async {
    HapticFeedback.selectionClick();
    setState(() => _isExporting = true);
    final logs = await FileLogger.getLogs();

    if (!mounted) return;

    if (logs == "No logs found.") {
      _showAlert('No Logs', 'There are no logs to export yet.');
      setState(() => _isExporting = false);
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/app_logs.txt');
    if (await file.exists()) {
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Last Mile Tracker Logs');
    }
    setState(() => _isExporting = false);
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
    HapticFeedback.mediumImpact();
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
              HapticFeedback.heavyImpact();
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
