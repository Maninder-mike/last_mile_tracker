import 'dart:ui';
import 'package:flutter/cupertino.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Decoration? decoration;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.1,
    this.borderRadius = 24.0,
    this.padding,
    this.margin,
    this.border,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget current = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration:
              decoration ??
              BoxDecoration(
                color: (isDark ? CupertinoColors.black : CupertinoColors.white)
                    .withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(borderRadius),
                border:
                    border ??
                    Border.all(
                      color:
                          (isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black)
                              .withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? CupertinoColors.white : CupertinoColors.white)
                        .withValues(alpha: isDark ? 0.05 : 0.2),
                    (isDark ? CupertinoColors.black : CupertinoColors.black)
                        .withValues(alpha: isDark ? 0.1 : 0.05),
                  ],
                ),
              ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      current = Padding(padding: margin!, child: current);
    }

    return current;
  }
}
