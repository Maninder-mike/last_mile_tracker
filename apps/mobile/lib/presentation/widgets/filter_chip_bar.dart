import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/app_layout.dart';

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
    final primaryColor = theme.primaryColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: AppPadding.horizontal,
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;

          return Padding(
            padding: EdgeInsets.only(right: AppTheme.s8),
            child: Semantics(
              label: '${item.label} filter',
              selected: isSelected,
              button: true,
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
                  // Ensure minimum touch target height of 44px
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.s16,
                    vertical: AppTheme.s12, // Increased for better touch target
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDark
                              ? CupertinoColors.white.withValues(alpha: 0.1)
                              : CupertinoColors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isDark
                                ? CupertinoColors.white.withValues(alpha: 0.2)
                                : CupertinoColors.black.withValues(alpha: 0.1)),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.label,
                      style: AppTheme.caption.copyWith(
                        color: isSelected
                            ? CupertinoColors.white
                            : primaryColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
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
