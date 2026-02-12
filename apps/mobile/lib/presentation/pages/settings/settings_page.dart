import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:last_mile_tracker/presentation/providers/theme_provider.dart';

import 'package:last_mile_tracker/core/config/support_config.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/service_providers.dart';
import 'package:last_mile_tracker/presentation/providers/settings_mode_provider.dart';
import '../../widgets/floating_header.dart';
import 'settings_theme.dart';
import 'widgets/settings_tile.dart';
import 'widgets/device_card.dart';
import 'advanced_settings_page.dart';
import 'notifications_settings_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(settingsModeProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              bottom: 100,
            ),
            children: [
              const DeviceCard().animate().fadeIn().slideY(begin: -0.1, end: 0),

              if (role != SettingsRole.driver) _buildOperationsSection(),
              _buildAppearanceSection(),
              _buildNotificationsSection(),
              _buildSupportSection(),

              // Always show Advanced for now to allow role switching,
              // but normally this would be role-gated.
              _buildAdvancedSectionEntry(),

              _buildFooter(),
              // Role Switcher for testing/demo purposes
              _buildRoleSwitcher(role),
            ],
          ),
          const FloatingHeader(title: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildOperationsSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('OPERATIONS'),
      margin: SettingsTheme.sectionMargin,
      children: [
        SettingsTile(
          title: 'Cloud Sync',
          subtitle: 'Sync telemetry to portal',
          icon: CupertinoIcons.cloud_upload,
          iconColor: CupertinoColors.systemIndigo,
          trailing: _isSyncing
              ? const CupertinoActivityIndicator(radius: 8)
              : const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: SettingsTheme.chevronColor,
                ),
          onTap: _isSyncing ? null : _handleCloudSync,
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return CupertinoListSection.insetGrouped(
      header: const Text('APPEARANCE'),
      margin: SettingsTheme.sectionMargin,
      children: [
        _buildThemeModeItem(themeState, themeNotifier),
        CupertinoListTile(
          title: const Text('Accent Color'),
          subtitle: const Text('Personalize your workspace'),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: themeState.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.paintbrush,
              color: themeState.accentColor,
              size: 20,
            ),
          ),
          additionalInfo: SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: [
                _buildColorOption(
                  CupertinoColors.activeBlue,
                  themeState,
                  themeNotifier,
                ),
                _buildColorOption(
                  CupertinoColors.systemPurple,
                  themeState,
                  themeNotifier,
                ),
                _buildColorOption(
                  CupertinoColors.systemOrange,
                  themeState,
                  themeNotifier,
                ),
                _buildColorOption(
                  CupertinoColors.systemIndigo,
                  themeState,
                  themeNotifier,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeItem(ThemeState state, ThemeNotifier notifier) {
    return CupertinoListTile(
      title: const Text('Theme Mode'),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.circle_lefthalf_fill,
          color: CupertinoColors.systemGrey,
          size: 20,
        ),
      ),
      additionalInfo: CupertinoSlidingSegmentedControl<AppThemeMode>(
        groupValue: state.mode,
        children: {
          AppThemeMode.system: const Text(
            'Auto',
            style: TextStyle(fontSize: 12),
          ),
          AppThemeMode.light: const Text(
            'Light',
            style: TextStyle(fontSize: 12),
          ),
          AppThemeMode.dark: const Text('Dark', style: TextStyle(fontSize: 12)),
        },
        onValueChanged: (value) {
          if (value != null) {
            HapticFeedback.selectionClick();
            notifier.setTheme(value);
          }
        },
      ),
    );
  }

  Widget _buildColorOption(
    Color color,
    ThemeState state,
    ThemeNotifier notifier,
  ) {
    final isSelected = state.accentColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        notifier.setAccentColor(color);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: CupertinoColors.white, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('PREFERENCES'),
      margin: SettingsTheme.sectionMargin,
      children: [
        SettingsTile(
          title: 'Notifications',
          icon: CupertinoIcons.bell,
          iconColor: CupertinoColors.systemRed,
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const NotificationSettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('HELP & SUPPORT'),
      margin: SettingsTheme.sectionMargin,
      children: [
        SettingsTile(
          title: 'Help Center',
          icon: CupertinoIcons.question_circle,
          iconColor: CupertinoColors.systemBlue,
          onTap: () => _launchUrl(SupportConfig.helpCenterUrl),
        ),
        SettingsTile(
          title: 'Contact Support',
          icon: CupertinoIcons.mail,
          iconColor: CupertinoColors.systemBlue,
          onTap: () => _launchUrl('mailto:support@example.com'),
        ),
      ],
    );
  }

  Widget _buildAdvancedSectionEntry() {
    return CupertinoListSection.insetGrouped(
      margin: SettingsTheme.sectionMargin,
      children: [
        SettingsTile(
          title: 'Advanced Settings',
          icon: CupertinoIcons.gear_alt,
          iconColor: CupertinoColors.systemGrey,
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const AdvancedSettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoleSwitcher(SettingsRole currentRole) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Text(
            'DEBUG: CURRENT ROLE',
            style: AppTheme.caption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 8),
          CupertinoSlidingSegmentedControl<SettingsRole>(
            groupValue: currentRole,
            children: const {
              SettingsRole.driver: Text('Driver'),
              SettingsRole.operations: Text('Ops'),
              SettingsRole.admin: Text('Admin'),
            },
            onValueChanged: (value) {
              if (value != null) {
                HapticFeedback.selectionClick();
                ref.read(settingsModeProvider.notifier).setRole(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 20),
        child: ref
            .watch(packageInfoProvider)
            .when(
              data: (info) => Column(
                children: [
                  Text(
                    'Version ${info.version} (${info.buildNumber})',
                    style: AppTheme.caption,
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
      ),
    );
  }

  Future<void> _handleCloudSync() async {
    HapticFeedback.selectionClick();
    setState(() => _isSyncing = true);
    // Simulate delay or real sync
    await Future.delayed(const Duration(seconds: 1));
    await ref.read(syncManagerProvider).syncData();
    if (mounted) {
      setState(() => _isSyncing = false);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      // Ignore errors for now
    }
  }
}
