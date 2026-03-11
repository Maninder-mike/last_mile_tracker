import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/domain/models/fleet_tracker.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/supabase_providers.dart';

// part 'fleet_tracker_provider.g.dart';

final fleetTrackersProvider = Provider<AsyncValue<List<FleetTracker>>>((ref) {
  final trackersAsync = ref.watch(allTrackersProvider);
  final scanResultsAsync = ref.watch(bleScanResultsProvider);
  final shipmentsAsync = ref.watch(shipmentsProvider);

  if (trackersAsync.isLoading ||
      scanResultsAsync.isLoading ||
      shipmentsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (trackersAsync.hasError) {
    return AsyncValue.error(trackersAsync.error!, trackersAsync.stackTrace!);
  }
  if (scanResultsAsync.hasError) {
    return AsyncValue.error(
      scanResultsAsync.error!,
      scanResultsAsync.stackTrace!,
    );
  }
  if (shipmentsAsync.hasError) {
    return AsyncValue.error(shipmentsAsync.error!, shipmentsAsync.stackTrace!);
  }

  final dbTrackers = trackersAsync.value ?? [];
  final scanResults = scanResultsAsync.value ?? [];
  final shipments = shipmentsAsync.value ?? [];

  // Map shipments by deviceId for quick lookup
  final shipmentMap = <String, Shipment>{};
  for (final s in shipments) {
    for (final deviceId in s.deviceIds) {
      shipmentMap[deviceId] = s;
    }
  }

  // Map scan results by remoteId for quick lookup
  final scanMap = {for (var s in scanResults) s.id: s};

  // Combine DB trackers with live scan status
  final fleetTrackers = dbTrackers.map((tracker) {
    final scanResult = scanMap[tracker.id];
    final shipment = shipmentMap[tracker.id];

    return FleetTracker.fromTracker(
      tracker,
      currentRssi: scanResult?.rssi,
      isInRange: scanResult != null,
      shipment: shipment,
    );
  }).toList();

  // Add any discovered trackers NOT yet in DB (though they should be synced fast)
  final existingIds = fleetTrackers.map((t) => t.id).toSet();
  for (final scanResult in scanResults) {
    if (!existingIds.contains(scanResult.id)) {
      final shipment = shipmentMap[scanResult.id];
      fleetTrackers.add(
        FleetTracker(
          id: scanResult.id,
          name: scanResult.name,
          batteryLevel: scanResult.telemetry?.batteryLevel,
          temp: scanResult.telemetry?.temp,
          rssi: scanResult.rssi,
          lastSeen: scanResult.lastSeen,
          isInRange: true,
          shipmentId: shipment?.id,
          trackingNumber: shipment?.trackingNumber,
          status: 'discovered',
        ),
      );
    }
  }

  // Sort: Favorites first, then In-Range, then Last Seen
  fleetTrackers.sort((a, b) {
    if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
    if (a.isInRange != b.isInRange) return a.isInRange ? -1 : 1;
    return b.lastSeen.compareTo(a.lastSeen);
  });

  return AsyncValue.data(fleetTrackers);
});
