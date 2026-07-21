import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final bool enabled;
  final bool _isPrimary;
  final String? semanticsLabel;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.gradient,
    this.borderRadius = AppTheme.radiusMedium,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTheme.s24,
      vertical: AppTheme.s16,
    ),
    this.width,
    this.height,
    this.enabled = true,
    this.semanticsLabel,
  }) : _isPrimary = false;

  AnimatedButton.primary({
    super.key,
    required String label,
    required this.onTap,
    this.width,
    this.height,
    this.enabled = true,
    Widget? icon,
    String? semanticsLabel,
  }) : child = Row(
         mainAxisAlignment: MainAxisAlignment.center,
         mainAxisSize: MainAxisSize.min,
         children: [
           if (icon != null) ...[icon, const SizedBox(width: 8)],
           Text(
             label,
             style: const TextStyle(
               color: CupertinoColors.white,
               fontWeight: FontWeight.w600,
               fontSize: 17,
             ),
           ),
         ],
       ),
       color = null,
       gradient = null,
       _isPrimary = true,
       semanticsLabel = semanticsLabel ?? label,
       borderRadius = AppTheme.radiusMedium,
       padding = const EdgeInsets.symmetric(
         horizontal: AppTheme.s24,
         vertical: AppTheme.s16,
       );

  const AnimatedButton.glass({
    super.key,
    required this.child,
    required this.onTap,
    this.width,
    this.height,
    this.enabled = true,
    this.semanticsLabel,
  }) : color = null,
       gradient = null,
       _isPrimary = false,
       borderRadius = AppTheme.radiusMedium,
       padding = const EdgeInsets.all(AppTheme.s16);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final primary = theme.primaryColor;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final effectiveOpacity = widget.enabled ? 1.0 : 0.5;

    Gradient? effectiveGradient = widget.gradient;
    List<BoxShadow>? effectiveShadow;
    final Color? resolvedColor = widget.color ?? (widget.gradient == null && !widget._isPrimary ? AppTheme.surfaceGlassWeak : null);

    if (widget._isPrimary) {
      final hsl = HSLColor.fromColor(primary);
      final Color startColor = isDark
          ? hsl
                .withSaturation((hsl.saturation + 0.15).clamp(0.0, 1.0))
                .withLightness((hsl.lightness + 0.05).clamp(0.0, 1.0))
                .toColor()
          : primary;
      final Color endColor = isDark
          ? hsl
                .withHue((hsl.hue + 15) % 360)
                .withSaturation((hsl.saturation + 0.15).clamp(0.0, 1.0))
                .withLightness((hsl.lightness - 0.02).clamp(0.0, 1.0))
                .toColor()
          : hsl
                .withHue((hsl.hue + 15) % 360)
                .withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0))
                .toColor();

      effectiveGradient = LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

      if (widget.enabled) {
        effectiveShadow = [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.4 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ];
      }
    } else if (widget.enabled && widget.gradient != null) {
      effectiveShadow = AppTheme.glowOf(context)
          .map(
            (e) => BoxShadow(
              color: e.color.withValues(alpha: isDark ? 0.4 : 0.3),
              blurRadius: e.blurRadius,
              offset: e.offset,
            ),
          )
          .toList();
    }

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) {
                if (widget.onTap != null) HapticFeedback.lightImpact();
                setState(() => _isPressed = true);
              }
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Opacity(
            opacity: effectiveOpacity,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: resolvedColor,
                gradient: effectiveGradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: widget._isPrimary && isDark
                    ? Border.all(
                        color: primary.withValues(alpha: 0.3),
                        width: 1.0,
                      )
                    : null,
                boxShadow: effectiveShadow,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
