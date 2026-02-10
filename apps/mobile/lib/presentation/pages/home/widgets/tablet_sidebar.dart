import 'package:flutter/cupertino.dart';
import '../../../widgets/connection_status_icon.dart';
import 'mobile_bottom_nav.dart';

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
      color: CupertinoColors.systemGroupedBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Tracker',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
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
                    color: isSelected ? CupertinoColors.activeBlue : null,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => onTap(index),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 20,
                          color: isSelected
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? CupertinoColors.white
                                : CupertinoColors.label,
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
                  color: CupertinoColors.white,
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
