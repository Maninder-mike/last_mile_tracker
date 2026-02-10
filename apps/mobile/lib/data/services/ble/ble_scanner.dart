import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lmt_models/lmt_models.dart';
import '../../../core/constants/ble_constants.dart';
import '../../../core/utils/file_logger.dart';
import 'scanned_tracker.dart';
import 'sensor_data_parser.dart';

class BleScanner {
  StreamSubscription? _scanSubscription;
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// Accumulated list of unique devices found during the current/last scan.
  final List<ScannedTracker> _discoveredDevices = [];
  StreamController<List<ScannedTracker>> _discoveredController =
      StreamController<List<ScannedTracker>>.broadcast();
  bool _isDisposed = false;

  /// Stream of all discovered devices
  Stream<List<ScannedTracker>> get discoveredDevices async* {
    yield List.unmodifiable(_discoveredDevices);
    if (!_isDisposed) {
      yield* _discoveredController.stream;
    }
  }

  BleScanner();

  /// Re-creates the broadcast controller if it was previously closed.
  void _ensureController() {
    if (_isDisposed) {
      _discoveredController =
          StreamController<List<ScannedTracker>>.broadcast();
      _isDisposed = false;
    }
  }

  Future<void> start() async {
    _ensureController();

    // Small delay to ensure previous UI transitions or adapter states settle
    await Future.delayed(BleConstants.scanStartDelay);

    if (await FlutterBluePlus.isScanning.first) {
      FileLogger.log("Scanner: Already scanning. Skipping.");
      return;
    }

    if (await FlutterBluePlus.isSupported == false) {
      FileLogger.log("Scanner: Bluetooth not supported");
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      FileLogger.log("Scanner: Adapter is not on. Waiting...");
      return;
    }

    if (Platform.isAndroid) {
      if (!await _requestPermissions()) return;
    }

    FileLogger.log("Scanner: Starting fleet scan...");
    _isScanning = true;
    _discoveredDevices
        .clear(); // Clear previous results on new scan?? Or keep them?
    _discoveredController.add(List.unmodifiable(_discoveredDevices));

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult result in results) {
        if (_isTargetDevice(result)) {
          final telemetry = _extractTelemetry(result);
          final newTracker = ScannedTracker(
            device: result.device,
            rssi: result.rssi,
            lastSeen: DateTime.now(),
            telemetry: telemetry,
          );

          final index = _discoveredDevices.indexWhere(
            (t) => t.device.remoteId == result.device.remoteId,
          );
          if (index != -1) {
            _discoveredDevices[index] = newTracker;
          } else {
            _discoveredDevices.add(newTracker);
            FileLogger.log(
              "Scanner: Discovered ${result.device.platformName} [RSSI: ${result.rssi}]",
            );
          }
        }
      }
      _discoveredController.add(List.unmodifiable(_discoveredDevices));
    }, onError: (e) => FileLogger.log("Scanner: Scan stream error: $e"));

    try {
      await FlutterBluePlus.startScan(
        timeout: BleConstants.scanTimeout,
        androidUsesFineLocation: true,
      );
    } catch (e) {
      FileLogger.log("Scanner: Start scan error: $e");
      _isScanning = false;
    }
  }

  SensorReading? _extractTelemetry(ScanResult result) {
    // 1. Try Service Data (UUID 181A)
    final serviceData = result.advertisementData.serviceData;

    for (final entry in serviceData.entries) {
      if (entry.key.toString().toUpperCase().contains(
        BleConstants.serviceUuid,
      )) {
        return SensorDataParser.parse(entry.value);
      }
    }

    // 2. Try Manufacturer Data (Any ID)
    final manufData = result.advertisementData.manufacturerData;
    for (final entry in manufData.entries) {
      if (entry.value.length >= BleConstants.packetLength) {
        return SensorDataParser.parse(entry.value);
      }
    }

    return null;
  }

  Future<void> stop() async {
    try {
      _isScanning = false;
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      FileLogger.log("Scanner: Stop scan error: $e");
    }
  }

  bool _isTargetDevice(ScanResult result) {
    final name = result.device.platformName;
    final advName = result.advertisementData.advName;
    return name == BleConstants.deviceName ||
        advName == BleConstants.deviceName ||
        name.startsWith(BleConstants.deviceName) ||
        advName.startsWith(BleConstants.deviceName);
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (statuses[Permission.bluetoothScan]?.isDenied == true ||
        statuses[Permission.bluetoothConnect]?.isDenied == true) {
      FileLogger.log("Scanner: Permissions denied!");
      return false;
    }
    return true;
  }

  void dispose() {
    stop();
    _isDisposed = true;
    _discoveredController.close();
  }
}
