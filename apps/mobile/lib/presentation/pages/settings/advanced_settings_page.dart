import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';
import 'settings_theme.dart';
import 'widgets/settings_tile.dart';
import 'widgets/firmware_update_tile.dart';
import 'widgets/glass_settings_section.dart';
import '../../widgets/floating_header.dart';

class AdvancedSettingsPage extends ConsumerStatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  ConsumerState<AdvancedSettingsPage> createState() =>
      _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends ConsumerState<AdvancedSettingsPage> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              bottom: 40,
            ),
            children: [
              _buildUpdatesSection(),
              _buildDataSection(),
              _buildDeveloperSection(),
              _buildDangerZone(),
            ],
          ),
          const FloatingHeader(title: 'Advanced', showBackButton: true),
        ],
      ),
    );
  }

  Widget _buildUpdatesSection() {
    return const GlassSettingsSection(
      title: 'Firmware & System',
      children: [FirmwareUpdateTile()],
    );
  }

  Widget _buildDataSection() {
    return GlassSettingsSection(
      title: 'Data Management',
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
                  size: 16,
                  color: SettingsTheme.chevronColor,
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

  Widget _buildDangerZone() {
    return GlassSettingsSection(
      title: 'Danger Zone',
      children: [
        SettingsTile(
          title: 'Reboot Device',
          subtitle: 'Restarts the device remotely',
          icon: CupertinoIcons.restart,
          iconColor: CupertinoColors.destructiveRed,
          isDestructive: true,
          onTap: () => _showConfirmationDialog(
            title: 'Reboot Device',
            message:
                'Are you sure you want to reboot the tracker? It will disconnect temporarily.',
            confirmLabel: 'Reboot',
            onConfirm: () => _handleDeviceAction(
              action: () => ref.read(bleServiceProvider).rebootDevice(),
              successMessage: 'Reboot command sent. Device is restarting.',
            ),
          ),
        ),
        SettingsTile(
          title: 'Reset WiFi Config',
          subtitle: 'Clears saved credentials',
          icon: CupertinoIcons.wifi_exclamationmark,
          iconColor: CupertinoColors.destructiveRed,
          isDestructive: true,
          onTap: () => _showConfirmationDialog(
            title: 'Reset WiFi',
            message:
                'This will clear the saved WiFi name and password. You will need to re-provision the device.',
            confirmLabel: 'Reset',
            onConfirm: () => _handleDeviceAction(
              action: () => ref.read(bleServiceProvider).resetWifiConfig(),
              successMessage: 'WiFi configuration has been cleared.',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleExportLogs() async {
    HapticFeedback.selectionClick();
    setState(() => _isExporting = true);

    try {
      final logs = await FileLogger.getLogs();

      if (!mounted) return;

      if (logs == "No logs found.") {
        _showAlert('No Logs', 'There are no logs to export yet.');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_logs.txt');

      if (!await file.exists()) {
        await file.writeAsString(logs);
      }

      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Last Mile Tracker Logs',
          ),
        );
      } else {
        _showAlert('Export Failed', 'Could not generate log file.');
      }
    } catch (e) {
      _showAlert('Export Error', 'An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleDeviceAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    HapticFeedback.mediumImpact();
    // In a real app we might show a spinner here, but for now just the action
    try {
      await action();
      if (mounted) {
        _showAlert('Command Sent', successMessage);
      }
    } catch (e) {
      if (mounted) _showAlert('Error', e.toString());
    }
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
            child: const Text('Delete All'),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              await ref.read(sensorDaoProvider).deleteAllReadings();
              if (mounted) {
                _showAlert('Success', 'Local database has been cleared.');
              }
            },
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

  void _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(confirmLabel),
          ),
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

  Widget _buildDeveloperSection() {
    final simulationState = ref.watch(simulationStateProvider);

    return GlassSettingsSection(
      title: 'Developer',
      children: [
        SettingsTile(
          title: 'Simulate Tracker Data',
          subtitle: 'Generate fake sensor & WiFi data',
          icon: CupertinoIcons.lab_flask,
          iconColor: CupertinoColors.systemPurple,
          trailing: CupertinoSwitch(
            value: simulationState.value ?? false,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(bleServiceProvider).toggleSimulation();
            },
          ),
        ),
      ],
    );
  }
}
