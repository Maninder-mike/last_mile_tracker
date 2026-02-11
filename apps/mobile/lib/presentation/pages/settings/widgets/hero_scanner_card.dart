import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lmt_models/lmt_models.dart' as models;
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import '../../../widgets/glass_container.dart';
import '../settings_theme.dart';

class HeroScannerCard extends StatelessWidget {
  final BluetoothConnectionState connectionState;
  final models.SensorReading? latestReading;

  const HeroScannerCard({
    super.key,
    required this.connectionState,
    this.latestReading,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = connectionState == BluetoothConnectionState.connected;
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassContainer(
      margin: SettingsTheme.heroMargin,
      padding: SettingsTheme.heroPadding,
      // Use default GlassContainer opacity/color which adapts to theme
      // opacity: isDark ? SettingsTheme.glassOpacityDark : SettingsTheme.glassOpacityLight,
      borderRadius: 24,
      child: Column(
        children: [
          Row(
            children: [
              _buildStatusIcon(isConnected),
              const SizedBox(width: 16),
              _buildTitleSection(isConnected, isDark),
            ],
          ),
          if (isConnected) ...[
            _buildDivider(isDark),
            _buildStatsSection(latestReading),
          ] else ...[
            _buildDivider(isDark),
            _buildOfflinePlaceholder(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool isConnected) {
    return Container(
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
    );
  }

  Widget _buildTitleSection(bool isConnected, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isConnected ? 'Tracker Online' : 'Tracker Offline',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: SettingsTheme.heroTitleSize,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              Icon(
                CupertinoIcons.bluetooth,
                size: 12,
                color: isConnected
                    ? CupertinoColors.activeGreen
                    : SettingsTheme.subtitleColor,
              ),
              const SizedBox(width: 4),
              Text(
                isConnected ? 'BLE Connected' : 'BLE Disconnected',
                style: const TextStyle(
                  color: SettingsTheme.subtitleColor,
                  fontSize: 12,
                ),
              ),
              if (isConnected && latestReading?.wifiSsid != null) ...[
                const SizedBox(width: 12),
                const Icon(
                  CupertinoIcons.wifi,
                  size: 12,
                  color: CupertinoColors.activeGreen,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    latestReading!.wifiSsid!,
                    style: const TextStyle(
                      color: SettingsTheme.subtitleColor,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        height: 0.5,
        color: isDark
            ? SettingsTheme.dividerColorDark
            : SettingsTheme.dividerColorLight,
      ),
    );
  }

  Widget _buildStatsSection(models.SensorReading? latest) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _HeroStat(
          label: 'Temp',
          value: latest != null
              ? '${latest.temp.toStringAsFixed(1)}°C'
              : '--°C',
        ),
        _HeroStat(
          label: 'Signal',
          value: latest != null ? '${latest.rssi ?? -60} dBm' : '-- dBm',
        ),
        _HeroStat(
          label: 'Battery',
          value: latest != null
              ? '${latest.batteryLevel.toStringAsFixed(1)}V'
              : '--V',
        ),
      ],
    );
  }

  Widget _buildOfflinePlaceholder() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _HeroStat(label: 'Temp', value: '--'),
        _HeroStat(label: 'Signal', value: '--'),
        _HeroStat(label: 'Battery', value: '--'),
      ],
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: SettingsTheme.heroValueSize,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: SettingsTheme.subtitleColor,
            fontSize: SettingsTheme.heroLabelSize,
          ),
        ),
      ],
    );
  }
}
