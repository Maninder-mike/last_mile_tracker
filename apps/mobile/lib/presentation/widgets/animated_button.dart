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
  });

  AnimatedButton.primary({
    super.key,
    required String label,
    required this.onTap,
    this.width,
    this.height,
    this.enabled = true,
    Widget? icon,
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
       gradient = AppTheme.primaryGradient,
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
  }) : color = AppTheme.surfaceGlassWeak,
       gradient = null,
       borderRadius = AppTheme.radiusMedium,
       padding = const EdgeInsets.all(AppTheme.s16);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = widget.enabled ? 1.0 : 0.5;

    return GestureDetector(
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
              color: widget.color,
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: widget.enabled && widget.gradient != null
                  ? AppTheme.glow
                        .map(
                          (e) => BoxShadow(
                            color: e.color.withValues(alpha: 0.3),
                            blurRadius: e.blurRadius,
                            offset: e.offset,
                          ),
                        )
                        .toList()
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
