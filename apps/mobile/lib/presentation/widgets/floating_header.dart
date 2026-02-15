import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/network_provider.dart';
import 'glass_container.dart';
import 'connection_status_icon.dart';
import 'connectivity_indicator.dart';

class FloatingHeader extends ConsumerWidget {
  final String title;
  final bool showBackButton;
  final Widget? trailing;
  final bool wrapTrailing;

  const FloatingHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.trailing,
    this.wrapTrailing = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isOnline = ref.watch(isOnlineProvider);

    Widget defaultTrailing() {
      if (isOnline) {
        return const ConnectionStatusIcon();
      }
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConnectivityIndicator(),
          SizedBox(width: AppTheme.s8),
          ConnectionStatusIcon(),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.s16,
          vertical: AppTheme.s8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Back Button + Title
            if (showBackButton) ...[
              Semantics(
                label: 'Back',
                button: true,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(
                    AppTheme.iconSizeMedium,
                    AppTheme.iconSizeMedium,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                  child: GlassContainer(
                    borderRadius: 30,
                    opacity: 0.1,
                    padding: const EdgeInsets.all(AppTheme.s12),
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      size: AppTheme.iconSizeMedium,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.s8),
            ],
            GlassContainer(
              borderRadius: 30,
              opacity: 0.1,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Spacer(),
            // Right: Trailing widget or default connection icon
            if (wrapTrailing)
              GlassContainer(
                borderRadius: 30,
                opacity: 0.1,
                padding: const EdgeInsets.all(AppTheme.s12),
                child: trailing ?? defaultTrailing(),
              )
            else
              trailing ?? defaultTrailing(),
          ],
        ),
      ),
    );
  }
}
