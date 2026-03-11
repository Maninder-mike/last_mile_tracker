import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:last_mile_tracker/data/database/app_database.dart';
import 'package:last_mile_tracker/data/repositories/tracker_repository.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';

// part 'tracker_providers.g.dart';

final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  final trackerDao = ref.watch(trackerDaoProvider);
  final repository = TrackerRepository(bleService, trackerDao);
  repository.startSync(); // Start syncing immediately when watched
  return repository;
});

final allTrackersProvider = StreamProvider<List<Tracker>>((ref) {
  final repository = ref.watch(trackerRepositoryProvider);
  return repository.watchAllTrackers();
});

final trackerProvider = StreamProvider.family<Tracker?, String>((ref, id) {
  final repository = ref.watch(trackerRepositoryProvider);
  return repository.watchTracker(id);
});
