import 'package:flutter/cupertino.dart';
import '../settings_theme.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
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
              style: const TextStyle(color: SettingsTheme.subtitleColor),
            )
          : null,
      leading: Container(
        width: SettingsTheme.tileLeadingSize,
        height: SettingsTheme.tileLeadingSize,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: isDark ? 0.2 : 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: SettingsTheme.tileIconSize),
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: SettingsTheme.chevronColor,
                )
              : null),
      onTap: onTap,
    );
  }
}
