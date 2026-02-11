import 'package:flutter/cupertino.dart';
import '../../../widgets/connection_status_icon.dart';
import 'mobile_bottom_nav.dart';
import '../../../../core/theme/app_theme.dart';

class TabletSidebar extends StatelessWidget {
  final int currentIndex;
  final List<HomeMenuItem> items;
  final ValueChanged<int> onTap;

  const TabletSidebar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Tracker',
                style: AppTheme.heading1.copyWith(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: isSelected ? AppTheme.primary : null,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => onTap(index),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 20,
                          color: isSelected
                              ? CupertinoColors.white
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          item.label,
                          style: AppTheme.body.copyWith(
                            color: isSelected
                                ? CupertinoColors.white
                                : AppTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Spacer(),
                    ConnectionStatusIcon(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
