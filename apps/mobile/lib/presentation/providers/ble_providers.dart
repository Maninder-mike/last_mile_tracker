import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/data/services/ble_service.dart';
import 'package:last_mile_tracker/data/services/ble/ble_connection_manager.dart';
import 'package:last_mile_tracker/data/services/ble/scanned_tracker.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';

part 'ble_providers.g.dart';

@Riverpod(keepAlive: true)
BleService bleService(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  final service = BleService(dao);
  service.startScanning(); // Auto-start scanning on app launch
  ref.onDispose(() => service.dispose());
  return service;
}

// BLE Connection State Provider
@riverpod
Stream<BluetoothConnectionState> bleConnectionState(Ref ref) {
  final service = ref.watch(bleServiceProvider);
  return service.connectionState;
}

// BLE Discovered Devices Provider
@riverpod
Stream<List<ScannedTracker>> bleScanResults(Ref ref) {
  final service = ref.watch(bleServiceProvider);
  return service.discoveredDevices;
}

@riverpod
Stream<List<WifiScanResult>> wifiScanResults(Ref ref) {
  final service = ref.watch(bleServiceProvider);
  return service.wifiScanResults;
}

@riverpod
Stream<bool> isWifiScanning(Ref ref) {
  final service = ref.watch(bleServiceProvider);
  return service.isWifiScanning;
}

@riverpod
Stream<String> wifiStatus(Ref ref) {
  final service = ref.watch(bleServiceProvider);
  return service.wifiStatus;
}

@riverpod
Stream<bool> simulationState(Ref ref) async* {
  final service = ref.watch(bleServiceProvider);
  yield service.simulationActive;
  yield* service.simulationState;
}
