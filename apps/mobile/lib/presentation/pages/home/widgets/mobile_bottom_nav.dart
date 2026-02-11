import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, HitTestBehavior;
import '../../../widgets/glass_container.dart';
import '../../../../core/theme/app_theme.dart';

class MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<HomeMenuItem> items;
  final ValueChanged<int> onTap;

  const MobileBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 8,
      child: SafeArea(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          borderRadius: 32,
          color: AppTheme.surfaceGlass,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: AppTheme.caption.copyWith(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class HomeMenuItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const HomeMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
