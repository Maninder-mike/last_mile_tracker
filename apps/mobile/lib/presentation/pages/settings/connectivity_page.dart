import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/constants/ble_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lmt_models/lmt_models.dart' as models;
import 'package:last_mile_tracker/data/services/ble_service.dart';
import '../../providers/ble_providers.dart';
import '../../providers/database_providers.dart';
import '../../widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/data/services/ble/scanned_tracker.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

class ConnectivityPage extends ConsumerStatefulWidget {
  const ConnectivityPage({super.key});

  @override
  ConsumerState<ConnectivityPage> createState() => _ConnectivityPageState();
}

class _ConnectivityPageState extends ConsumerState<ConnectivityPage> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSending = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendWifiCredentials() async {
    final ssid = _ssidController.text;
    final password = _passwordController.text;

    if (ssid.isEmpty) {
      _showError('SSID cannot be empty');
      return;
    }

    setState(() => _isSending = true);

    try {
      await ref.read(bleServiceProvider).writeWifiConfig(ssid, password);

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Provisioning Started'),
            content: Text(
              'WiFi credentials for "$ssid" have been sent to the tracker. (Password: ${password.isNotEmpty ? "********" : "None"})',
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
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Connectivity Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bleConnected = ref.watch(bleConnectionStateProvider).value;
    final isConnected = bleConnected == BluetoothConnectionState.connected;
    final bleService = ref.read(bleServiceProvider);
    final latestReading = ref.watch(latestReadingProvider).value;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Listen for WiFi Status Updates
    ref.listen<AsyncValue<String>>(wifiStatusProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final status = next.value!;
        if (status.startsWith(BleConstants.wifiConnectedPrefix)) {
          final ssid = status.split(":").last;
          _showSuccess(
            "WiFi Connected",
            "Device successfully connected to $ssid",
          );
        } else if (status.startsWith(BleConstants.wifiFailedPrefix)) {
          final reason = status.split(":").last;
          _showError("WiFi Connection Failed: $reason");
        }
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              bottom: 40,
            ),
            children: [
              // Connection Status Cards
              _buildStatusCards(
                isConnected,
                latestReading,
                isDark,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

              // WiFi Provisioning (Gated by connection)
              if (isConnected) ...[
                _buildProvisioningSection(isDark),
                _buildDeviceToolsSection(isConnected, latestReading),
                const SizedBox(height: 64),
              ] else ...[
                _buildConnectionRequiredPlaceholder(isDark),
              ],

              // Bluetooth Actions
              _buildBluetoothSection(bleService),

              // Scan Results
              _buildScanResultsSection(isDark),
            ],
          ),
          const FloatingHeader(title: 'Connectivity', showBackButton: true),
        ],
      ),
    );
  }

  Widget _buildStatusCards(
    bool bleConnected,
    models.SensorReading? latest,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceGlass,
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.bluetooth,
                    color: bleConnected
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bleConnected ? 'Connected' : 'Disconnected',
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Bluetooth',
                    style: AppTheme.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceGlass,
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.wifi,
                    color: (latest?.wifiSsid != null)
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    latest?.wifiSsid ?? 'Not Linked',
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'WiFi Network',
                    style: AppTheme.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeviceDetails(ScannedTracker tracker) {
    FileLogger.log(
      "UI: Showing details for device ${tracker.device.remoteId.str}",
    );
    final device = tracker.device;
    final adv = tracker.advertisementData;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          device.platformName.isEmpty ? 'Unknown Device' : device.platformName,
        ),
        message: Column(
          children: [
            _buildDetailRow('Remote ID', device.remoteId.toString()),
            _buildDetailRow('RSSI', '${tracker.rssi} dBm'),
            if (adv != null) ...[
              _buildDetailRow('Connectable', adv.connectable.toString()),
              if (adv.txPowerLevel != null)
                _buildDetailRow('TX Power', '${adv.txPowerLevel} dBm'),
              if (adv.serviceUuids.isNotEmpty)
                _buildDetailRow('Service UUIDs', adv.serviceUuids.join(', ')),
              if (adv.manufacturerData.isNotEmpty)
                _buildDetailRow(
                  'Manuf. Data',
                  _formatBytes(adv.manufacturerData.values.first),
                ),
              if (adv.serviceData.isNotEmpty)
                _buildDetailRow(
                  'Service Data',
                  _formatBytes(adv.serviceData.values.first),
                ),
            ] else
              _buildDetailRow('Status', 'System Connected / Bonded'),
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Connect'),
            onPressed: () {
              Navigator.pop(context);
              ref.read(bleServiceProvider).connect(device);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Copy ID'),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: device.remoteId.toString()),
              );
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ')
        .toUpperCase();
  }

  Future<void> _handleDeviceAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    HapticFeedback.mediumImpact();
    setState(() => _isSending = true);

    try {
      await action();
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Command Sent'),
            content: Text(successMessage),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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

  Widget _buildProvisioningSection(bool isDark) {
    return CupertinoFormSection.insetGrouped(
      header: const Text('WIFI PROVISIONING'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: [
        CupertinoFormRow(
          prefix: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(CupertinoIcons.wifi, size: 20),
              SizedBox(width: 8),
              Text('Network SSID'),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _ssidController,
                  placeholder: 'Required',
                  textAlign: TextAlign.right,
                  decoration: null,
                  style: TextStyle(
                    color: CupertinoDynamicColor.resolve(
                      AppTheme.textPrimary,
                      context,
                    ),
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: _showWifiScanModal,
                child: Icon(
                  CupertinoIcons.search,
                  size: 20,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        CupertinoFormRow(
          prefix: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(CupertinoIcons.lock_shield, size: 20),
              SizedBox(width: 8),
              Text('Password'),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _passwordController,
                  placeholder: 'Optional',
                  obscureText: _obscurePassword,
                  textAlign: TextAlign.right,
                  decoration: null,
                  style: TextStyle(
                    color: CupertinoDynamicColor.resolve(
                      AppTheme.textPrimary,
                      context,
                    ),
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? CupertinoIcons.eye
                      : CupertinoIcons.eye_slash,
                  size: 18,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: CupertinoButton.filled(
            onPressed: (_isSending) ? null : _sendWifiCredentials,
            child: _isSending
                ? const CupertinoActivityIndicator()
                : const Text('Update WiFi Config'),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceToolsSection(
    bool isConnected,
    models.SensorReading? latestReading,
  ) {
    if (!isConnected) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, top: 24, bottom: 8),
          child: Text(
            'LIVE DIAGNOSTICS',
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _buildDiagnosticsGrid(latestReading),
        Padding(
          padding: EdgeInsets.only(left: 16, top: 24, bottom: 8),
          child: Text(
            'DEVICE MANAGEMENT',
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        GlassContainer(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildToolAction(
                icon: CupertinoIcons.info_circle,
                title: 'Identify Device',
                subtitle: 'Blinks the device LED',
                onTap: () => _handleDeviceAction(
                  action: () => ref.read(bleServiceProvider).identifyDevice(),
                  successMessage: 'Identification command sent.',
                ),
              ),
              _buildDivider(),
              _buildToolAction(
                icon: CupertinoIcons.restart,
                title: 'Reboot Device',
                subtitle: 'Restarts the device remotely',
                textColor: CupertinoColors.systemRed,
                onTap: () => _showConfirmationDialog(
                  title: 'Reboot Device',
                  message:
                      'Are you sure you want to reboot the tracker? It will disconnect temporarily.',
                  confirmLabel: 'Reboot',
                  onConfirm: () => _handleDeviceAction(
                    action: () => ref.read(bleServiceProvider).rebootDevice(),
                    successMessage:
                        'Reboot command sent. Device is restarting.',
                  ),
                ),
              ),
              _buildDivider(),
              _buildToolAction(
                icon: CupertinoIcons.wifi_exclamationmark,
                title: 'Reset WiFi Config',
                subtitle: 'Clears saved credentials',
                textColor: CupertinoColors.systemRed,
                onTap: () => _showConfirmationDialog(
                  title: 'Reset WiFi',
                  message:
                      'This will clear the saved WiFi name and password. You will need to re-provision the device.',
                  confirmLabel: 'Reset',
                  onConfirm: () => _handleDeviceAction(
                    action: () =>
                        ref.read(bleServiceProvider).resetWifiConfig(),
                    successMessage: 'WiFi configuration has been cleared.',
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildDiagnosticsGrid(models.SensorReading? reading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
        children: [
          _buildDiagCard(
            icon: CupertinoIcons.battery_100,
            value: '${(reading?.batteryLevel ?? 0.0).toStringAsFixed(1)}V',
            label: 'Battery',
            color: _getBatteryColor(reading?.batteryLevel ?? 0),
          ),
          _buildDiagCard(
            icon: CupertinoIcons.antenna_radiowaves_left_right,
            value: '${reading?.rssi ?? "--"} dBm',
            label: 'Signal',
            color: _getSignalColor(reading?.rssi ?? -100),
          ),
          _buildDiagCard(
            icon: CupertinoIcons.timer,
            value: _formatUptime(reading?.uptime ?? 0),
            label: 'Uptime',
            color: CupertinoTheme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      color: AppTheme.surfaceGlass,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Color _getBatteryColor(double voltage) {
    if (voltage > 3.8) return CupertinoColors.systemGreen;
    if (voltage > 3.5) return CupertinoColors.systemYellow;
    return CupertinoColors.systemRed;
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return CupertinoColors.systemGreen;
    if (rssi > -80) return CupertinoColors.systemYellow;
    return CupertinoColors.systemRed;
  }

  String _formatUptime(int seconds) {
    if (seconds == 0) return "--";
    final Duration d = Duration(seconds: seconds);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${seconds}s';
  }

  Widget _buildToolAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? textColor,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (textColor ?? CupertinoTheme.of(context).primaryColor)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: textColor ?? CupertinoTheme.of(context).primaryColor,
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
                    style: TextStyle(
                      color: textColor ?? CupertinoColors.label,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: CupertinoColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.withValues(alpha: 0.1),
      ),
    );
  }

  void _showWifiScanModal() {
    ref.read(bleServiceProvider).scanForWifi();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 500,
        padding: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Network',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: CupertinoColors.separator),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final scanResults =
                      ref.watch(wifiScanResultsProvider).value ?? [];
                  final isScanning =
                      ref.watch(isWifiScanningProvider).value ?? false;

                  if (isScanning && scanResults.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoActivityIndicator(),
                          SizedBox(height: 16),
                          Text("Scanning for networks..."),
                        ],
                      ),
                    );
                  }

                  if (scanResults.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.wifi_slash,
                            size: 48,
                            color: CupertinoColors.systemGrey,
                          ),
                          const SizedBox(height: 16),
                          const Text("No networks found"),
                          const SizedBox(height: 8),
                          CupertinoButton(
                            child: const Text("Scan Again"),
                            onPressed: () =>
                                ref.read(bleServiceProvider).scanForWifi(),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: scanResults.length,
                    separatorBuilder: (context, index) => Container(
                      height: 1,
                      color: CupertinoColors.separator,
                      margin: const EdgeInsets.only(left: 16),
                    ),
                    itemBuilder: (context, index) {
                      final network = scanResults[index];
                      return CupertinoListTile(
                        title: Text(network.ssid),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${network.rssi} dBm",
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(CupertinoIcons.wifi),
                          ],
                        ),
                        onTap: () {
                          setState(() => _ssidController.text = network.ssid);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothSection(BleService bleService) {
    final isScanning = bleService.isScanning;
    return CupertinoListSection.insetGrouped(
      header: const Text('BLUETOOTH CONTROLS'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: [
        CupertinoListTile(
          title: Text(isScanning ? 'Scanning...' : 'Scan for Devices'),
          leading: isScanning
              ? const CupertinoActivityIndicator()
              : const Icon(CupertinoIcons.refresh_circled),
          onTap: isScanning ? null : () => bleService.startScanning(),
        ),
        CupertinoListTile(
          title: const Text(
            'Force Disconnect',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
          leading: const Icon(
            CupertinoIcons.xmark_circle,
            color: CupertinoColors.destructiveRed,
          ),
          onTap: () => bleService.dispose(),
        ),
      ],
    );
  }

  Widget _buildScanResultsSection(bool isDark) {
    final scanResults = ref.watch(bleScanResultsProvider).value ?? [];
    if (scanResults.isEmpty) return const SizedBox.shrink();

    final bleService = ref.read(bleServiceProvider);

    return CupertinoListSection.insetGrouped(
      header: const Text('DISCOVERED DEVICES'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final result in scanResults)
          CupertinoListTile(
            title: Text(
              result.device.platformName.isEmpty
                  ? 'Unknown Device'
                  : result.device.platformName,
            ),
            subtitle: Text(result.device.remoteId.toString()),
            leading: const Icon(CupertinoIcons.bluetooth),
            onTap: () {
              FileLogger.log(
                "UI: Tapped on device tile ${result.device.remoteId.str}",
              );
              _showDeviceDetails(result);
            },
            trailing: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('Connect'),
              onPressed: () => bleService.connect(result.device),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionRequiredPlaceholder(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        opacity: isDark ? 0.05 : 0.08,
        borderRadius: 20,
        child: Column(
          children: [
            Icon(
              CupertinoIcons.antenna_radiowaves_left_right,
              size: 48,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connection Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect to a tracker to configure WiFi & Tools.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () => ref.read(bleServiceProvider).startScanning(),
              child: const Text('Scan for Devices'),
            ),
          ],
        ),
      ),
    );
  }
}
