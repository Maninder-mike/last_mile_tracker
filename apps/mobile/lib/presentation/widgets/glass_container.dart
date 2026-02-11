import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

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
    // If color is not provided, use surfaceGlass which has built-in opacity/color for light/dark.
    final baseColor = color ?? AppTheme.surfaceGlass;

    // Resolve dynamic color
    final resolvedColor = CupertinoDynamicColor.resolve(baseColor, context);

    // Only apply opacity override if specific color was NOT provided (to keep surfaceGlass effect)
    // OR if we want to force the 'opacity' parameter.
    // However, AppTheme.surfaceGlass already has 0xCC (80%).
    // Let's just use the resolved color directly if it's the default,
    // or apply opacity if it's a custom color without alpha.
    final finalColor = resolvedColor.withValues(
      alpha: color != null ? opacity : resolvedColor.a,
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
}
