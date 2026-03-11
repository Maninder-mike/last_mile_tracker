import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/trips.dart';

part 'trip_dao.g.dart';

@DriftAccessor(tables: [Trips])
class TripDao extends DatabaseAccessor<AppDatabase> {
  TripDao(super.db);

  TableInfo<Trips, Trip> get _trips => db.trips;

  // Start a new trip
  Future<String> startTrip() async {
    final id = 'trip-${DateTime.now().millisecondsSinceEpoch}';
    await into(
      _trips,
    ).insert(TripsCompanion.insert(id: id, startTime: DateTime.now()));
    return id;
  }

  // End an active trip
  Future<void> endTrip(
    String id, {
    double distance = 0.0,
    double maxSpeed = 0.0,
  }) async {
    await (update(_trips)..where((t) => t.id.equals(id))).write(
      TripsCompanion(
        endTime: Value(DateTime.now()),
        distance: Value(distance),
        maxSpeed: Value(maxSpeed),
      ),
    );
  }

  // Watch currently active trip (one with no end time)
  Stream<Trip?> watchActiveTrip() {
    return (select(
      _trips,
    )..where((t) => t.endTime.isNull())).watchSingleOrNull();
  }

  // Get all trips
  Stream<List<Trip>> watchAllTrips() {
    return (select(_trips)..orderBy([
          (t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc),
        ]))
        .watch();
  }
}
