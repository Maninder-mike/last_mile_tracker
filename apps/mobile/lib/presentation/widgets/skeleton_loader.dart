import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CupertinoDynamicColor.resolve(AppTheme.shimmerBase, context),
      highlightColor: CupertinoDynamicColor.resolve(
        AppTheme.shimmerHighlight,
        context,
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget shipmentCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surfaceGlass,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonLoader(width: 120, height: 20),
                const SkeletonLoader(width: 60, height: 20, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonLoader(width: 200, height: 16),
            const SizedBox(height: 8),
            const SkeletonLoader(width: 150, height: 14),
          ],
        ),
      ),
    );
  }

  static Widget deviceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.surfaceGlass,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SkeletonLoader(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SkeletonLoader(width: 120, height: 20),
                  const SizedBox(height: 8),
                  const SkeletonLoader(width: 180, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
