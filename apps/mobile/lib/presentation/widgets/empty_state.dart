import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/app_layout.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    
    return Center(
      child: Padding(
        padding: AppPadding.section,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.s24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: primaryColor.withValues(alpha: 0.5),
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
            AppGaps.standard,
            Text(
              subtitle,
              style: AppTheme.body.copyWith(
                color: CupertinoDynamicColor.resolve(
                  AppTheme.textSecondary,
                  context,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[AppGaps.xxLarge, action!],
          ],
        ),
      ),
    );
  }
}
