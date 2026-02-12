import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

class FilterItem<T> {
  final String label;
  final T value;

  FilterItem({required this.label, required this.value});
}

class FilterChipBar<T> extends StatelessWidget {
  final List<FilterItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const FilterChipBar({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  onSelected(item.value);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : (isDark
                            ? const Color(0x1AFFFFFF)
                            : const Color(0x0A000000)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : (isDark
                              ? const Color(0x33FFFFFF)
                              : const Color(0x1A000000)),
                    width: 1,
                  ),
                ),
                child: Text(
                  item.label,
                  style: AppTheme.caption.copyWith(
                    color: isSelected
                        ? CupertinoColors.white
                        : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
