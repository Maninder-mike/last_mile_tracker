import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/app_layout.dart';
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
    final primaryColor = theme.primaryColor;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(AppTheme.s24),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 48, color: primaryColor)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 2000.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              ),
        ),
        AppGaps.xLarge,
        Text(
          title,
          style: AppTheme.heading2.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        AppGaps.medium,
        Text(
          message,
          style: AppTheme.body.copyWith(
            color: CupertinoDynamicColor.resolve(
              AppTheme.textSecondary,
              context,
            ),
          ),
          textAlign: TextAlign.center,
        ),
        if (buttonText != null && onButtonPressed != null) ...[
          AppGaps.xLarge,
          CupertinoButton.filled(
            onPressed: onButtonPressed,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Text(buttonText!),
          ),
        ],
      ],
    );

    if (useGlass) {
      return Center(
        child: Padding(
          padding: AppPadding.section,
          child: GlassContainer(
            padding: EdgeInsets.all(AppTheme.s32),
            borderRadius: AppTheme.radiusLarge,
            opacity: isDark ? 0.05 : 0.08,
            child: content,
          ),
        ),
      );
    }

    return Center(
      child: Padding(padding: AppPadding.section, child: content),
    );
  }
}
