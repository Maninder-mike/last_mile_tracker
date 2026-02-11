import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lmt_models/lmt_models.dart' as models;
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/presentation/providers/service_providers.dart';
import '../../../widgets/glass_container.dart';
import '../connectivity_page.dart';

class DeviceCard extends ConsumerWidget {
  const DeviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleConnectionStateProvider).value;
    final latestReading = ref.watch(latestReadingProvider).value;
    final isConnected = bleState == BluetoothConnectionState.connected;
    final isSyncing = ref.watch(isSyncingProvider);

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      color: AppTheme.surfaceGlass,
      child: Column(
        children: [
          Row(
            children: [
              _buildStatusIcon(isConnected),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Tracker Online' : 'Tracker Offline',
                      style: AppTheme.heading2.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    _buildDeviceSubtitle(isConnected, latestReading),
                  ],
                ),
              ),
              if (isConnected)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(
                    CupertinoIcons.settings,
                    color: AppTheme.primary,
                  ),
                  onPressed: () => _navigateToConnectivity(context),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 16),
          if (isConnected)
            _buildConnectedStats(latestReading)
          else
            _buildConnectButton(context),
          if (isConnected) ...[
            const SizedBox(height: 16),
            _buildSyncAction(ref, isSyncing),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isConnected ? AppTheme.success : AppTheme.critical).withValues(
          alpha: 0.1,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isConnected
            ? CupertinoIcons.checkmark_seal_fill
            : CupertinoIcons.antenna_radiowaves_left_right,
        color: isConnected ? AppTheme.success : AppTheme.critical,
        size: 28,
      ),
    );
  }

  Widget _buildDeviceSubtitle(
    bool isConnected,
    models.SensorReading? latestReading,
  ) {
    if (!isConnected) {
      return Text('Connect to device to sync data', style: AppTheme.caption);
    }

    final wifiSsid = latestReading?.wifiSsid;
    if (wifiSsid != null) {
      return Row(
        children: [
          Icon(CupertinoIcons.wifi, size: 12, color: AppTheme.success),
          const SizedBox(width: 4),
          Text(wifiSsid, style: AppTheme.caption),
        ],
      );
    }
    return Text('Bluetooth Connected', style: AppTheme.caption);
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppTheme.textSecondary.withValues(alpha: 0.1),
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(vertical: 12),
        borderRadius: BorderRadius.circular(12),
        onPressed: () => _navigateToConnectivity(context),
        child: const Text(
          'Connect Tracker',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _navigateToConnectivity(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const ConnectivityPage()),
    );
  }

  // Helper provider for sync status if main isSyncing is local state
  // Ideally this should be from a provider. For now assuming we pass it or ref reads it.
  // Using a local provider pattern for now since _isSyncing was stateful in settings page.
  // We will fix this by moving sync state to a provider later if needed, but for now
  // let's assume we trigger sync from here.

  Widget _buildSyncAction(WidgetRef ref, bool isSyncing) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        onPressed: isSyncing
            ? null
            : () async {
                ref.read(isSyncingProvider.notifier).setSyncing(true);
                try {
                  await ref.read(syncManagerProvider).syncData();
                } finally {
                  ref.read(isSyncingProvider.notifier).setSyncing(false);
                }
              },
        child: isSyncing
            ? const CupertinoActivityIndicator()
            : Text(
                'Sync Now',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildConnectedStats(models.SensorReading? latest) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          'Battery',
          '${latest?.batteryLevel.toStringAsFixed(1) ?? "--"}V',
        ),
        _buildStatItem('Signal', '${latest?.rssi ?? "--"} dBm'),
        _buildStatItem('Temp', '${latest?.temp.toStringAsFixed(1) ?? "--"}°C'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTheme.body.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTheme.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}

// Temporary provider for sync state visualization until we migrate fully
final isSyncingProvider = NotifierProvider<IsSyncingNotifier, bool>(
  IsSyncingNotifier.new,
);

class IsSyncingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSyncing(bool value) {
    state = value;
  }
}
