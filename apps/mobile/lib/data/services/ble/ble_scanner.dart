import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/ble_constants.dart';
import '../../../core/utils/file_logger.dart';

class BleScanner {
  final Function(BluetoothDevice) onDeviceFound;

  StreamSubscription? _scanSubscription;
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// Accumulated list of unique devices found during the current/last scan.
  final List<ScanResult> _discoveredDevices = [];
  StreamController<List<ScanResult>> _discoveredController =
      StreamController<List<ScanResult>>.broadcast();
  bool _isDisposed = false;

  /// Stream of all discovered devices (persists after auto-connect).
  Stream<List<ScanResult>> get discoveredDevices async* {
    yield List.unmodifiable(_discoveredDevices);
    if (!_isDisposed) {
      yield* _discoveredController.stream;
    }
  }

  BleScanner({required this.onDeviceFound});

  /// Re-creates the broadcast controller if it was previously closed.
  void _ensureController() {
    if (_isDisposed) {
      _discoveredController = StreamController<List<ScanResult>>.broadcast();
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

    FileLogger.log("Scanner: Starting scan...");
    _isScanning = true;
    // Don't clear previous results so we keep the connected device visible
    // even if it stops advertising or doesn't show up in a new scan.
    _discoveredController.add(List.unmodifiable(_discoveredDevices));

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult result in results) {
        // Accumulate unique devices for the UI list
        final alreadySeen = _discoveredDevices.any(
          (d) => d.device.remoteId == result.device.remoteId,
        );
        if (!alreadySeen && result.device.platformName.isNotEmpty) {
          _discoveredDevices.add(result);
          _discoveredController.add(List.unmodifiable(_discoveredDevices));
        }

        // Auto-connect to the target device
        if (_isTargetDevice(result)) {
          FileLogger.log("Scanner: Found ${result.device.platformName}!");
          onDeviceFound(result.device);
          stop();
          return;
        }
      }
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
