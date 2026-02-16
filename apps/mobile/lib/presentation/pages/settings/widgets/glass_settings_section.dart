import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import '../settings_theme.dart';

class GlassSettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final String? footer;

  const GlassSettingsSection({
    super.key,
    this.title,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SettingsTheme.sectionMarginBottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                title!.toUpperCase(),
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          GlassContainer(
            padding: EdgeInsets.zero,
            opacity: 0.08,
            blur: 15,
            borderRadius: 16,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Container(
                      height: 1,
                      color: CupertinoColors.separator.withValues(alpha: 0.1),
                      margin: const EdgeInsets.only(left: 50),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
              child: Text(footer!, style: AppTheme.caption),
            ),
        ],
      ),
    );
  }
}
