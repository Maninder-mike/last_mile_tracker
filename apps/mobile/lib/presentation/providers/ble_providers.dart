import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/data/services/ble_service.dart';
import 'package:last_mile_tracker/data/services/ble/ble_connection_manager.dart';
import 'package:last_mile_tracker/data/services/ble/scanned_tracker.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';

// part 'ble_providers.g.dart';

final bleServiceProvider = Provider<BleService>((ref) {
  final dao = ref.watch(sensorDaoProvider);
  final service = BleService(dao);
  service.startScanning(); // Auto-start scanning on app launch
  ref.onDispose(() => service.dispose());
  return service;
});

// BLE Connection State Provider
final bleConnectionStateProvider = StreamProvider<BluetoothConnectionState>((
  ref,
) {
  final service = ref.watch(bleServiceProvider);
  return service.connectionState;
});

// BLE Discovered Devices Provider
final bleScanResultsProvider = StreamProvider<List<ScannedTracker>>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.discoveredDevices;
});

final wifiScanResultsProvider = StreamProvider<List<WifiScanResult>>((
  ref,
) async* {
  final service = ref.watch(bleServiceProvider);
  yield service.lastWifiResults;
  yield* service.wifiScanResults;
});

final isWifiScanningProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(bleServiceProvider);
  yield service.isWifiScanningState;
  yield* service.isWifiScanning;
});

final wifiStatusProvider = StreamProvider<String>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.wifiStatus;
});

final simulationStateProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(bleServiceProvider);
  yield service.simulationActive;
  yield* service.simulationState;
});

final deviceFirmwareVersionProvider = StreamProvider<String?>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.firmwareVersionStream;
});
