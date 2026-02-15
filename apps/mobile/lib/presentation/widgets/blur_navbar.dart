import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

class BlurNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BlurNavbarItem> items;

  const BlurNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final primaryColor = theme.primaryColor;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.s20,
        vertical: AppTheme.s24,
      ),
      borderRadius: 30,
      opacity: 0.8,
      padding: EdgeInsets.zero,
      child: Container(
        height: 70,
        alignment: Alignment.center, // Ensure row is centered if needed
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: isSelected
                    ? BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected
                          ? primaryColor
                          : CupertinoDynamicColor.resolve(
                              AppTheme.textSecondary,
                              context,
                            ),
                      size: 24,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class BlurNavbarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BlurNavbarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
