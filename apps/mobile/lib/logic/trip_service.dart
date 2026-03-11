import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:state_notifier/state_notifier.dart';
import '../presentation/providers/database_providers.dart';
import '../data/database/app_database.dart';
// import '../data/database/daos/trip_dao.dart';

// part 'trip_service.g.dart';

final tripServiceProvider = NotifierProvider<TripService, AsyncValue<void>>(() {
  return TripService();
});

class TripService extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String> startTrip() async {
    final dao = ref.read(tripDaoProvider);
    final tripId = await dao.startTrip();
    return tripId;
  }

  Future<void> endCurrentTrip({
    double distance = 0.0,
    double maxSpeed = 0.0,
  }) async {
    final dao = ref.read(tripDaoProvider);
    final activeTrip = await dao.watchActiveTrip().first;
    if (activeTrip != null) {
      await dao.endTrip(activeTrip.id, distance: distance, maxSpeed: maxSpeed);
    }
  }

  Stream<Trip?> watchActiveTrip() {
    return ref.read(tripDaoProvider).watchActiveTrip();
  }
}

final activeTripStreamProvider = StreamProvider<Trip?>((ref) {
  return ref.watch(tripServiceProvider.notifier).watchActiveTrip();
});
