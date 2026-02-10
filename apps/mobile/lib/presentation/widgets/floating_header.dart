import 'package:flutter/cupertino.dart';
import 'glass_container.dart';
import 'connection_status_icon.dart';

class FloatingHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final Widget? trailing;

  const FloatingHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Back Button + Title
            if (showBackButton) ...[
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.maybePop(context),
                child: GlassContainer(
                  borderRadius: 30,
                  opacity: 0.1,
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    CupertinoIcons.chevron_left,
                    size: 20,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
            GlassContainer(
              borderRadius: 30,
              opacity: 0.1,
              padding: const EdgeInsets.all(12),
              child: trailing ?? const ConnectionStatusIcon(),
            ),
          ],
        ),
      ),
    );
  }
}
