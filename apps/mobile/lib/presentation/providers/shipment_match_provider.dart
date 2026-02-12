import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/presentation/providers/supabase_providers.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:collection/collection.dart';
import 'optimistic_favorites_provider.dart';

part 'shipment_match_provider.g.dart';

@riverpod
AsyncValue<List<Shipment>> mergedShipments(Ref ref) {
  final shipmentsAsync = ref.watch(shipmentsProvider);
  final trackersAsync = ref.watch(allTrackersProvider);

  // Return loading/error early if either is not ready
  if (shipmentsAsync.isLoading || trackersAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (shipmentsAsync.hasError)
    return AsyncValue.error(shipmentsAsync.error!, shipmentsAsync.stackTrace!);
  if (trackersAsync.hasError)
    return AsyncValue.error(trackersAsync.error!, trackersAsync.stackTrace!);

  final shipments = shipmentsAsync.value ?? [];
  final trackers = trackersAsync.value ?? [];

  // Create a map for O(1) tracker lookup
  final trackerMap = {for (var t in trackers) t.id: t};

  final merged = shipments.map((s) {
    final trackerId = s.deviceIds.firstOrNull;
    if (trackerId != null) {
      final tracker = trackerMap[trackerId];
      if (tracker != null) {
        return s.copyWith(
          latitude: (tracker.lat ?? 0) != 0 ? (tracker.lat ?? 0) : s.latitude,
          longitude: (tracker.lon ?? 0) != 0 ? (tracker.lon ?? 0) : s.longitude,
          lastUpdate: tracker.lastSeen,
          isFavorite: ref.watch(isFavoriteProvider(tracker.id)),
        );
      }
    }
    return s;
  }).toList();

  return AsyncValue.data(merged);
}
