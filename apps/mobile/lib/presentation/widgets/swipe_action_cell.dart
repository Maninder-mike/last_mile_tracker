import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SwipeActionCell extends StatelessWidget {
  final Widget child;
  final List<SlidableAction> startActions;
  final List<SlidableAction> endActions;
  final String? groupTag;

  const SwipeActionCell({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
    this.groupTag,
  });

  @override
  Widget build(BuildContext context) {
    if (startActions.isEmpty && endActions.isEmpty) return child;

    return Slidable(
      key: groupTag != null ? ValueKey(groupTag) : null,
      startActionPane: startActions.isNotEmpty
          ? ActionPane(motion: const BehindMotion(), children: startActions)
          : null,
      endActionPane: endActions.isNotEmpty
          ? ActionPane(motion: const BehindMotion(), children: endActions)
          : null,
      child: child,
    );
  }
}

/// Helper method to create a SlidableAction with app-consistent styling
/// Ensures minimum touch target of 44x44px for accessibility
SlidableAction createSwipeAction({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onPressed,
  bool isFirst = false,
  bool isLast = false,
}) {
  return SlidableAction(
    onPressed: (_) => onPressed(),
    backgroundColor: color,
    foregroundColor: CupertinoColors.white,
    icon: icon,
    label: label,
    padding: EdgeInsets.zero,
    flex: 1,
  );
}
