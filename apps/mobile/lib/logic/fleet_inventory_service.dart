import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/logic/active_load_service.dart';
import 'package:last_mile_tracker/presentation/providers/fleet_tracker_provider.dart';
// import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:last_mile_tracker/logic/alert_manager.dart';

// part 'fleet_inventory_service.g.dart';

final fleetInventoryServiceProvider = Provider(
  (ref) => FleetInventoryService(ref),
);

class FleetInventoryService {
  final Ref ref;
  Timer? _checkTimer;

  FleetInventoryService(this.ref) {
    _startInventoryChecks();
    ref.onDispose(() => _checkTimer?.cancel());
  }

  void _startInventoryChecks() {
    // Run every 5 minutes
    _checkTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _reconcileInventory(),
    );
  }

  Future<void> _reconcileInventory() async {
    final activeIds = ref.read(activeLoadIdsProvider);
    if (activeIds.isEmpty) {
      return;
    }

    final trackersAsync = ref.read(fleetTrackersProvider);
    trackersAsync.whenData((trackers) {
      final alertManager = ref.read(alertManagerProvider);

      for (final id in activeIds) {
        final tracker = trackers.firstWhere(
          (t) => t.id == id,
          orElse: () => throw Exception('Tracker not found'),
        );

        // If a tracker in the active load hasn't been seen for > 15 mins
        final lastSeen = tracker.lastSeen;
        final now = DateTime.now();
        if (now.difference(lastSeen).inMinutes > 15) {
          alertManager.createAlert(
            title: 'Asset Missing',
            message:
                'Tracker ${tracker.name} has not been seen for 15+ minutes. Check load integrity.',
            type: 'critical',
            trackerId: tracker.id,
          );
        }
      }
    });
  }
}
