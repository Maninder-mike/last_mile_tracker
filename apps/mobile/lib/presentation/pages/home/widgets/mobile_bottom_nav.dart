import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, HitTestBehavior;
import '../../../widgets/glass_container.dart';

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
          opacity: 0.15,
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
                        ? CupertinoColors.activeBlue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
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
