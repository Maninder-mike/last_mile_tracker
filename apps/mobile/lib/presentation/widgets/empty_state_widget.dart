import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool useGlass;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.useGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 48, color: theme.primaryColor)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 2000.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.secondaryLabel,
          ),
          textAlign: TextAlign.center,
        ),
        if (buttonText != null && onButtonPressed != null) ...[
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: onButtonPressed,
            borderRadius: BorderRadius.circular(12),
            child: Text(buttonText!),
          ),
        ],
      ],
    );

    if (useGlass) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GlassContainer(
            padding: const EdgeInsets.all(32),
            borderRadius: 24,
            opacity: isDark ? 0.05 : 0.08,
            child: content,
          ),
        ),
      );
    }

    return Center(
      child: Padding(padding: const EdgeInsets.all(24.0), child: content),
    );
  }
}
