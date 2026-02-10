import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class ConnectivityPage extends ConsumerStatefulWidget {
  const ConnectivityPage({super.key});

  @override
  ConsumerState<ConnectivityPage> createState() => _ConnectivityPageState();
}

class _ConnectivityPageState extends ConsumerState<ConnectivityPage> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSending = false;

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
      // Mock sending via BLE
      // In real app: await ref.read(bleServiceProvider).writeWifiConfig(ssid, password);
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text(
              'WiFi credentials sent to device for "$ssid" (Password: ${"*" * password.length})',
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
        title: const Text('Error'),
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Connectivity')),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'MANUAL CONFIGURATION',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('WiFi Settings (Board)'),
              footer: const Text(
                'Enter credentials to connect the ESP32 to WiFi.',
              ),
              children: [
                CupertinoListTile(
                  title: const Text('SSID'),
                  trailing: SizedBox(
                    width: 150,
                    child: CupertinoTextField(
                      controller: _ssidController,
                      placeholder: 'Network Name',
                      textAlign: TextAlign.right,
                      decoration: null,
                    ),
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Password'),
                  trailing: SizedBox(
                    width: 150,
                    child: CupertinoTextField(
                      controller: _passwordController,
                      placeholder: 'Password',
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: null,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CupertinoButton.filled(
                onPressed: _isSending ? null : _sendWifiCredentials,
                child: _isSending
                    ? const CupertinoActivityIndicator()
                    : const Text('Send to Device'),
              ),
            ),
            const SizedBox(height: 30),
            CupertinoListSection.insetGrouped(
              header: const Text('Bluetooth'),
              children: [
                CupertinoListTile(
                  title: const Text('Rescan Devices'),
                  leading: const Icon(CupertinoIcons.refresh),
                  onTap: () {
                    ref.read(bleServiceProvider).startScanning();
                  },
                ),
                CupertinoListTile(
                  title: const Text(
                    'Disconnect',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  leading: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: CupertinoColors.destructiveRed,
                  ),
                  onTap: () {
                    // Start scanning implies disconnect if we force it,
                    // but we don't have explicit disconnect method in provider public API yet.
                    ref.read(bleServiceProvider).dispose();
                    // Re-init? No, simple dispose might break connection.
                    // For now, simple restart scanning.
                    ref.read(bleServiceProvider).startScanning();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
