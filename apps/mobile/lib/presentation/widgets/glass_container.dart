import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/presentation/theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.7,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 16.0,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    // Use the provided color or fallback to the theme's glass surface color
    final effectiveColor = CupertinoDynamicColor.resolve(
      color ?? AppTheme.surfaceGlass,
      context,
    );

    // Calculate effective opacity based on whether it's the dynamic theme color or custom
    final finalColor = effectiveColor.withValues(
      alpha: color == null
          ? (_isDark(context) ? 0.6 : 0.8) // Tuning opacity for light/dark
          : opacity,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border:
            border ??
            Border.all(
              color: CupertinoDynamicColor.resolve(
                AppTheme.textSecondary,
                context,
              ).withValues(alpha: 0.1),
              width: 0.5,
            ),
        // Subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(padding: padding, color: finalColor, child: child),
        ),
      ),
    );
  }

  bool _isDark(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark;
  }
}
