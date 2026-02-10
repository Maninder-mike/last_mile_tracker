import 'package:flutter/cupertino.dart';
import 'glass_container.dart';
import 'connection_status_icon.dart';

class FloatingHeader extends StatelessWidget {
  final String title;

  const FloatingHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final topPadding = MediaQuery.of(context).padding.top + 8;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Left: Title
        Positioned(
          top: topPadding,
          left: 16,
          child: GlassContainer(
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
        ),
        // Right: Connection Status
        Positioned(
          top: topPadding,
          right: 16,
          child: GlassContainer(
            borderRadius: 30,
            opacity: 0.1,
            padding: const EdgeInsets.all(12),
            child: const ConnectionStatusIcon(),
          ),
        ),
      ],
    );
  }
}
