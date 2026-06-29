import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import '../settings_theme.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final Color rawTextColor = isDestructive
        ? AppTheme.critical
        : (enabled ? AppTheme.textPrimary : AppTheme.textSecondary);
    final Color effectiveTextColor = CupertinoDynamicColor.resolve(rawTextColor, context);

    final Color rawIconColor = enabled
        ? (isDestructive ? AppTheme.critical : iconColor)
        : AppTheme.textSecondary;
    final Color effectiveIconColor = CupertinoDynamicColor.resolve(rawIconColor, context);

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: CupertinoListTile(
        title: Text(
          title,
          style: AppTheme.body.copyWith(
            fontWeight: FontWeight.w500,
            color: effectiveTextColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.resolvedTextSecondary(context),
                ),
              )
            : null,
        leading: Container(
          width: SettingsTheme.tileLeadingSize,
          height: SettingsTheme.tileLeadingSize,
          decoration: BoxDecoration(
            color: effectiveIconColor.withValues(alpha: isDark ? 0.2 : 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              color: effectiveIconColor,
              size: SettingsTheme.tileIconSize,
            ),
          ),
        ),
        trailing:
            trailing ??
            (onTap != null && enabled
                ? const Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: SettingsTheme.chevronColor,
                  )
                : null),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
