import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/domain/models/fleet_tracker.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/logic/active_load_service.dart';

class ActiveLoadCard extends ConsumerWidget {
  final List<FleetTracker> allTrackers;
  final VoidCallback onVerify;

  const ActiveLoadCard({
    super.key,
    required this.allTrackers,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIds = ref.watch(activeLoadIdsProvider);
    if (activeIds.isEmpty) return const SizedBox.shrink();

    final myTrackers = allTrackers
        .where((t) => activeIds.contains(t.id))
        .toList();
    final inRangeCount = myTrackers.where((t) => t.isInRange).length;
    final totalCount = myTrackers.length;
    final isComplete = inRangeCount == totalCount;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.15),
          primaryColor.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: isComplete ? AppTheme.success : primaryColor,
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Truck', style: AppTheme.heading2),
                  Text(
                    '$totalCount assigned trackers',
                    style: AppTheme.caption,
                  ),
                ],
              ),
              _buildStatusIcon(isComplete, primaryColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$inRangeCount / $totalCount in range',
                      style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProgressBar(inRangeCount / totalCount, primaryColor),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: isComplete ? AppTheme.success : primaryColor,
                borderRadius: BorderRadius.circular(20),
                onPressed: onVerify,
                child: Text(
                  isComplete ? 'VERIFIED' : 'VERIFY',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool isComplete, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isComplete ? AppTheme.success : primaryColor).withValues(
          alpha: 0.1,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isComplete
            ? CupertinoIcons.check_mark_circled_solid
            : CupertinoIcons.bus,
        color: isComplete ? AppTheme.success : primaryColor,
        size: 20,
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color primaryColor) {
    return Stack(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
