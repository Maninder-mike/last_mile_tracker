import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import '../../widgets/floating_header.dart';
import 'settings_theme.dart';
import 'widgets/settings_tile.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

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
              CupertinoListSection.insetGrouped(
                header: const Text('ALERTS'),
                margin: SettingsTheme.sectionMargin,
                children: [
                  _buildSwitchTile(context, 'Battery Low', true),
                  _buildSwitchTile(context, 'Temperature Alert', true),
                  _buildSwitchTile(context, 'Connection Lost', false),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('UPDATES'),
                margin: SettingsTheme.sectionMargin,
                children: [
                  _buildSwitchTile(context, 'Shipment Status', true),
                  _buildSwitchTile(context, 'Firmware Updates', true),
                ],
              ),
            ],
          ),
          const FloatingHeader(title: 'Notifications', showBackButton: true),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, bool value) {
    return SettingsTile(
      title: title,
      icon: CupertinoIcons.bell,
      iconColor: CupertinoTheme.of(context).primaryColor,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: (v) {}, // No-op for now
      ),
    );
  }
}
