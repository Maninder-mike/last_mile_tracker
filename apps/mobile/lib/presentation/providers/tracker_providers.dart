import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:last_mile_tracker/data/database/app_database.dart';
import 'package:last_mile_tracker/data/repositories/tracker_repository.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/logic/alert_manager.dart';

part 'tracker_providers.g.dart';

@Riverpod(keepAlive: true)
AlertManager alertManager(Ref ref) {
  final bleService = ref.watch(bleServiceProvider);
  final alertDao = ref.watch(alertDaoProvider);
  final manager = AlertManager(bleService, alertDao);
  manager.startMonitoring();
  return manager;
}

@Riverpod(keepAlive: true)
TrackerRepository trackerRepository(Ref ref) {
  final bleService = ref.watch(bleServiceProvider);
  final trackerDao = ref.watch(trackerDaoProvider);
  final repository = TrackerRepository(bleService, trackerDao);
  repository.startSync(); // Start syncing immediately when watched
  return repository;
}

final allTrackersProvider = StreamProvider<List<Tracker>>((ref) {
  final repository = ref.watch(trackerRepositoryProvider);
  return repository.watchAllTrackers();
});
