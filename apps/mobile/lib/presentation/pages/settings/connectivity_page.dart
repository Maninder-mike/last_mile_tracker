import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lmt_models/lmt_models.dart' as models;
import 'package:last_mile_tracker/data/services/ble_service.dart';
import '../../providers/ble_providers.dart';
import '../../providers/database_providers.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/floating_header.dart';

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

  @override
  Widget build(BuildContext context) {
    final bleService = ref.watch(bleServiceProvider);
    final isConnected =
        bleService.lastState == BluetoothConnectionState.connected;
    final latestReading = ref.watch(latestReadingProvider).value;

    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

              // WiFi Provisioning Section (Gated by connection)
              if (isConnected) ...[
                _buildProvisioningSection(isDark),
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
              opacity: isDark ? 0.05 : 0.08,
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.bluetooth,
                    color: bleConnected
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.systemGrey,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bleConnected ? 'Connected' : 'Disconnected',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Bluetooth',
                    style: TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              opacity: isDark ? 0.05 : 0.08,
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.wifi,
                    color: (latest?.wifiSsid != null)
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.systemGrey,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    latest?.wifiSsid ?? 'Not Linked',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'WiFi Network',
                    style: TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvisioningSection(bool isDark) {
    return CupertinoListSection.insetGrouped(
      header: const Text('WIFI PROVISIONING'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: [
        CupertinoListTile(
          title: const Text('Network SSID'),
          leading: const Icon(CupertinoIcons.wifi, size: 20),
          trailing: Expanded(
            child: CupertinoTextField(
              controller: _ssidController,
              placeholder: 'Required',
              textAlign: TextAlign.right,
              decoration: null,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Password'),
          leading: const Icon(CupertinoIcons.lock_shield, size: 20),
          trailing: Row(
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
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(
                  _obscurePassword
                      ? CupertinoIcons.eye
                      : CupertinoIcons.eye_slash,
                  size: 18,
                  color: CupertinoColors.systemGrey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
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
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
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
              color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connection Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please connect to a Last Mile Tracker via Bluetooth to configure WiFi settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }
}
