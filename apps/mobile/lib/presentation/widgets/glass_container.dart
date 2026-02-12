import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

class GlassContainer extends StatefulWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.7,
    this.padding = const EdgeInsets.all(AppTheme.s16),
    this.margin,
    this.borderRadius = 16.0,
    this.color,
    this.border,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? AppTheme.surfaceGlass;
    final resolvedColor = CupertinoDynamicColor.resolve(baseColor, context);

    final finalColor = resolvedColor.withValues(
      alpha: widget.color != null ? widget.opacity : resolvedColor.a,
    );

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) {
              HapticFeedback.lightImpact();
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
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border:
                widget.border ??
                Border.all(
                  color: CupertinoDynamicColor.resolve(
                    AppTheme.textSecondary,
                    context,
                  ).withValues(alpha: 0.1),
                  width: 0.5,
                ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(
                  alpha: _isPressed ? 0.02 : 0.05,
                ),
                blurRadius: _isPressed ? 4 : 10,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blur,
                sigmaY: widget.blur,
              ),
              child: Container(
                padding: widget.padding,
                color: finalColor,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
