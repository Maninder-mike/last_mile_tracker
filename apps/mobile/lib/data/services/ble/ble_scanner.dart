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

    // Prevent hitting Android scan frequency limits
    if (await FlutterBluePlus.isScanning.first) {
      FileLogger.log("Scanner: Already scanning. Skipping redundant start.");
      return;
    }

    if (await FlutterBluePlus.isSupported == false) {
      FileLogger.log("Scanner: Bluetooth not supported");
      return;
    }

    // Wait for Bluetooth to be on
    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      FileLogger.log(
        "Scanner: Adapter not ready (State: $adapterState). Waiting for Bluetooth...",
      );
      try {
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        FileLogger.log("Scanner: Bluetooth failed to turn on in time.");
        return;
      }
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
        // DEBUG LOGGING
        final devName = result.device.platformName;
        final advName = result.advertisementData.advName;
        FileLogger.log(
          "Scanner: Saw device: '$devName' / '$advName' [${result.rssi}]",
        );

        if (_isTargetDevice(result)) {
          FileLogger.log(
            "Scanner: MATCHED device: '$devName' [${result.rssi}]",
          );

          final telemetry = _extractTelemetry(result);
          final newTracker = ScannedTracker(
            device: result.device,
            rssi: result.rssi,
            lastSeen: DateTime.now(),
            advertisementData: result.advertisementData,
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

  /// Checks OS-level connected and bonded devices.
  /// Useful for quick reconnection without full scan.
  Future<void> checkKnownDevices() async {
    _ensureController();
    FileLogger.log("Scanner: Checking known/connected devices...");

    try {
      // 1. Check devices currently connected to the system
      final connected = FlutterBluePlus.connectedDevices;
      for (var device in connected) {
        if (_isTargetDeviceFromDevice(device)) {
          _addDeviceToDiscovered(device, rssi: -50); // Dummy RSSI
        }
      }

      // 2. Check bonded devices (Android only)
      if (Platform.isAndroid) {
        final bonded = await FlutterBluePlus.bondedDevices;
        for (var device in bonded) {
          if (_isTargetDeviceFromDevice(device)) {
            _addDeviceToDiscovered(device, rssi: -60); // Dummy RSSI
          }
        }
      }

      _discoveredController.add(List.unmodifiable(_discoveredDevices));
    } catch (e) {
      FileLogger.log("Scanner: checkKnownDevices error: $e");
    }
  }

  bool _isTargetDeviceFromDevice(BluetoothDevice device) {
    final name = device.platformName;
    return name == BleConstants.deviceName ||
        name.startsWith(BleConstants.deviceName);
  }

  void _addDeviceToDiscovered(BluetoothDevice device, {required int rssi}) {
    final index = _discoveredDevices.indexWhere(
      (t) => t.device.remoteId == device.remoteId,
    );
    if (index == -1) {
      _discoveredDevices.add(
        ScannedTracker(
          device: device,
          rssi: rssi,
          lastSeen: DateTime.now(),
          advertisementData:
              null, // No advertisement data available for connected devices
          telemetry: null,
        ),
      );
      FileLogger.log("Scanner: Picked up known device: ${device.platformName}");
    }
  }

  /// Updates the telemetry for a specific device.
  /// Used for connected devices receiving data via notifications.
  void updateDeviceTelemetry(
    DeviceIdentifier remoteId,
    SensorReading telemetry,
  ) {
    final index = _discoveredDevices.indexWhere(
      (t) => t.device.remoteId == remoteId,
    );
    if (index != -1) {
      _discoveredDevices[index] = _discoveredDevices[index].copyWith(
        telemetry: telemetry,
        lastSeen: DateTime.now(),
      );
      _discoveredController.add(List.unmodifiable(_discoveredDevices));
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
    // 1. Check Name
    final name = result.device.platformName;
    final advName = result.advertisementData.advName;
    final nameMatch =
        name == BleConstants.deviceName ||
        advName == BleConstants.deviceName ||
        name.startsWith(BleConstants.deviceName) ||
        advName.startsWith(BleConstants.deviceName);

    if (nameMatch) return true;

    // 2. Check Service UUID (for cases where name is cached as empty)
    // Guid comparison handles normalization
    if (result.advertisementData.serviceUuids.contains(
      Guid(BleConstants.serviceUuid),
    )) {
      return true;
    }

    return false;
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
