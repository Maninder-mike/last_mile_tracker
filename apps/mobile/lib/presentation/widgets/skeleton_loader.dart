import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/app_layout.dart';

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
      padding: EdgeInsets.symmetric(vertical: AppTheme.s8),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surfaceGlass,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        padding: AppPadding.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonLoader(width: 120, height: 20),
                const SkeletonLoader(
                  width: 60,
                  height: 20,
                  borderRadius: 12,
                ),
              ],
            ),
            AppGaps.large,
            const SkeletonLoader(width: 200, height: 16),
            AppGaps.medium,
            const SkeletonLoader(width: 150, height: 14),
          ],
        ),
      ),
    );
  }

  static Widget deviceCard() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.s8),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.surfaceGlass,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        padding: AppPadding.card,
        child: Row(
          children: [
            const SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: 24,
            ),
            AppGaps.horizontalLarge,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SkeletonLoader(width: 120, height: 20),
                  AppGaps.medium,
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
