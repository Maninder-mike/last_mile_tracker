import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

class GlassContainer extends StatefulWidget {
  final Widget child;
  final double blur;
  final double? opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final BoxShape shape;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity,
    this.padding = const EdgeInsets.all(AppTheme.s16),
    this.margin,
    this.borderRadius = AppTheme.radiusMedium,
    this.color,
    this.gradient,
    this.border,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    // Determine background color/alpha
    final baseColor = widget.color ?? AppTheme.surfaceGlass;
    final resolvedColor = CupertinoDynamicColor.resolve(baseColor, context);

    // Calculate final background color if no gradient is present
    final effectiveOpacity =
        widget.opacity ??
        (widget.color != null
            ? (resolvedColor.a == 1.0 ? 0.7 : resolvedColor.a)
            : (isDark ? 0.85 : resolvedColor.a));

    final finalColor = widget.gradient == null
        ? resolvedColor.withValues(alpha: effectiveOpacity)
        : null;

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) {
              if (widget.onTap != null) HapticFeedback.selectionClick();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.onDoubleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            border:
                widget.border ??
                Border.all(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.08)
                      : CupertinoColors.white.withValues(alpha: 0.6),
                  width: isDark ? 0.5 : 1.0,
                ),
            boxShadow: [
              if (!_isPressed) ...[
                BoxShadow(
                  color: CupertinoColors.black.withValues(
                    alpha: isDark ? 0.2 : 0.05,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
                if (isDark)
                  BoxShadow(
                    color: CupertinoTheme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.03),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ],
          ),
          child: widget.shape == BoxShape.circle
              ? ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blur,
                      sigmaY: widget.blur,
                    ),
                    child: Container(
                      padding: widget.padding,
                      decoration: BoxDecoration(
                        color: finalColor,
                        gradient: widget.gradient,
                        shape: BoxShape.circle,
                      ),
                      child: widget.child,
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blur,
                      sigmaY: widget.blur,
                    ),
                    child: Container(
                      padding: widget.padding,
                      decoration: BoxDecoration(
                        color: finalColor,
                        gradient: widget.gradient,
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
