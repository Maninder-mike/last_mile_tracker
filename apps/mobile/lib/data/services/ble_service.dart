import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/ble_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/sensor_dao.dart';
import '../../core/utils/file_logger.dart';

class BleService {
  final SensorDao _sensorDao;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _characteristicSubscription;

  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState {
    Future.microtask(() => _connectionStateController.add(_lastState));
    return _connectionStateController.stream;
  }

  BluetoothConnectionState _lastState = BluetoothConnectionState.disconnected;
  BluetoothConnectionState get lastState => _lastState;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  int _reconnectDelaySeconds = 1;
  static const int _maxReconnectDelaySeconds = 32;

  // Data buffering for high-frequency sensor readings
  final List<SensorReadingsCompanion> _readingsBuffer = [];
  static const int _bufferThreshold = 10;
  Timer? _bufferTimer;

  // OTA write handles
  BluetoothCharacteristic? _otaControlChar;
  BluetoothCharacteristic? _otaDataChar;

  BleService(this._sensorDao) {
    _startBufferTimer();
  }

  void _startBufferTimer() {
    _bufferTimer?.cancel();
    _bufferTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _flushBuffer();
    });
  }

  Future<void> _flushBuffer() async {
    if (_readingsBuffer.isEmpty) return;

    final batch = List<SensorReadingsCompanion>.from(_readingsBuffer);
    _readingsBuffer.clear();

    try {
      await _sensorDao.insertReadingsBatch(batch);
      FileLogger.log("BLE: Flushed ${batch.length} readings to DB.");
    } catch (e) {
      FileLogger.log("BLE: Buffer flush error: $e");
      // Optionally put back to buffer if it's a transient DB error
      _readingsBuffer.addAll(batch);
    }
  }

  Future<void> startScanning() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (await FlutterBluePlus.isScanning.first) {
      FileLogger.log("BLE: Already scanning. Skipping.");
      return;
    }

    if (await FlutterBluePlus.isSupported == false) {
      FileLogger.log("BLE: Bluetooth not supported");
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      FileLogger.log("BLE: Adapter is not on. Waiting...");
      Timer(const Duration(seconds: 2), () => startScanning());
      return;
    }

    if (Platform.isAndroid) {
      if (!await _requestPermissions()) return;
    }

    FileLogger.log("BLE: Starting scan...");
    _isScanning = true;
    _connectionStateController.add(_lastState);

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult result in results) {
        if (_isTargetDevice(result)) {
          FileLogger.log(
            "BLE: Found ${result.device.platformName}! Connecting...",
          );
          _connectToDevice(result.device);
          _stopScanning();
          break;
        }
      }
    }, onError: (e) => FileLogger.log("BLE: Scan stream error: $e"));

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      FileLogger.log("BLE: Start scan error: $e");
    }
  }

  Future<void> _stopScanning() async {
    try {
      _isScanning = false;
      _connectionStateController.add(_lastState);
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      FileLogger.log("BLE: Stop scan error: $e");
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
    var statusScan = await Permission.bluetoothScan.status;
    var statusConnect = await Permission.bluetoothConnect.status;

    if (!statusScan.isGranted || !statusConnect.isGranted) {
      FileLogger.log("BLE: Requesting Android 12+ permissions...");
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      if (statuses[Permission.bluetoothScan]?.isDenied == true ||
          statuses[Permission.bluetoothConnect]?.isDenied == true) {
        FileLogger.log("BLE: Permissions denied!");
        return false;
      }
    }
    return true;
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      FileLogger.log("BLE: Connected to ${device.platformName}");
      _reconnectDelaySeconds = 1;

      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((state) {
        _lastState = state;
        _connectionStateController.add(state);

        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnectionResources();
          FileLogger.log(
            "BLE: Disconnected. Retrying in $_reconnectDelaySeconds s...",
          );
          Timer(
            Duration(seconds: _reconnectDelaySeconds),
            () => startScanning(),
          );
          _reconnectDelaySeconds = (_reconnectDelaySeconds * 2).clamp(
            1,
            _maxReconnectDelaySeconds,
          );
        }
      });

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        final uuid = service.uuid.toString().toUpperCase();
        if (uuid.contains(BleConstants.serviceUuid)) {
          FileLogger.log("BLE: Found Service ${service.uuid}");
          for (var characteristic in service.characteristics) {
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              await _characteristicSubscription?.cancel();
              _characteristicSubscription = characteristic.lastValueStream
                  .listen((value) {
                    _parseAndBufferData(value);
                  });
              FileLogger.log("BLE: Subscribed to ${characteristic.uuid}");
            }
          }
        }

        // Discover OTA characteristics
        for (var characteristic in service.characteristics) {
          final charUuid = characteristic.uuid.toString().toUpperCase();
          if (charUuid == BleConstants.otaControlUuid.toUpperCase()) {
            _otaControlChar = characteristic;
            FileLogger.log("BLE: Found OTA Control characteristic");
          } else if (charUuid == BleConstants.otaDataUuid.toUpperCase()) {
            _otaDataChar = characteristic;
            FileLogger.log("BLE: Found OTA Data characteristic");
          }
        }
      }
    } catch (e) {
      FileLogger.log("BLE: Connection/Discovery error: $e");
      _cleanupConnectionResources();
      startScanning();
    }
  }

  void _cleanupConnectionResources() {
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    _otaControlChar = null;
    _otaDataChar = null;
  }

  /// Write to OTA Control characteristic (CMD_START, CMD_END)
  Future<void> writeOtaControl(Uint8List data) async {
    final char = _otaControlChar;
    if (char == null) {
      throw Exception(
        'OTA Control characteristic not found. Reconnect device.',
      );
    }
    await char.write(data, withoutResponse: false);
  }

  /// Write to OTA Data characteristic (CMD_DATA chunks, without response for speed)
  Future<void> writeOtaData(Uint8List data) async {
    final char = _otaDataChar;
    if (char == null) {
      throw Exception('OTA Data characteristic not found. Reconnect device.');
    }
    await char.write(data, withoutResponse: true);
  }

  void _parseAndBufferData(List<int> bytes) {
    if (bytes.length < 24) return;

    try {
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      double lat = data.getFloat32(0, Endian.little);
      double lon = data.getFloat32(4, Endian.little);
      int speedraw = data.getUint16(8, Endian.little);
      int tempraw = data.getInt16(10, Endian.little);
      int shock = data.getUint16(12, Endian.little);
      int batMv = data.getUint16(14, Endian.little);
      int intTempRaw = data.getInt16(16, Endian.little);
      int tripState = data.getUint8(18);
      int resetReason = data.getUint8(19);
      int uptime = data.getUint32(20, Endian.little);

      double speed = speedraw / 100.0;
      double temp = tempraw / 100.0;
      double internalTemp = intTempRaw / 100.0;
      double batteryLevel = batMv / 1000.0; // Convert mV to V

      final reading = SensorReadingsCompanion(
        timestamp: drift.Value(DateTime.now()),
        lat: drift.Value(lat),
        lon: drift.Value(lon),
        speed: drift.Value(speed),
        temp: drift.Value(temp),
        shockValue: drift.Value(shock),
        batteryLevel: drift.Value(batteryLevel),
        internalTemp: drift.Value(internalTemp),
        tripState: drift.Value(tripState),
        resetReason: drift.Value(resetReason),
        uptime: drift.Value(uptime),
        isSynced: const drift.Value(false),
      );

      _readingsBuffer.add(reading);

      if (_readingsBuffer.length >= _bufferThreshold) {
        _flushBuffer();
      }
    } catch (e) {
      FileLogger.log("BLE Parse Error: $e");
    }
  }

  Timer? _simulationTimer;
  bool _isSimulating = false;
  bool get simulationActive => _isSimulating;

  void toggleSimulation() {
    if (_isSimulating) {
      _stopSimulation();
    } else {
      _startSimulation();
    }
  }

  void _startSimulation() {
    if (_isSimulating) return;
    _isSimulating = true;
    FileLogger.log("BLE: Starting Simulation Mode");

    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final random = DateTime.now().millisecondsSinceEpoch;
      final speed = 15.0 + (random % 100) / 10.0;
      final temp = 20.0 + (random % 50) / 10.0;
      final shock = (random % 5);

      _readingsBuffer.add(
        SensorReadingsCompanion(
          timestamp: drift.Value(DateTime.now()),
          lat: drift.Value(37.7749 + (random % 1000) / 100000.0),
          lon: drift.Value(-122.4194 + (random % 1000) / 100000.0),
          speed: drift.Value(speed),
          temp: drift.Value(temp),
          shockValue: drift.Value(shock),
          batteryLevel: drift.Value(3.7 + (random % 30) / 100.0), // 3.7-4.0V
          internalTemp: drift.Value(45.0 + (random % 100) / 10.0), // 45-55C
          tripState: const drift.Value(1), // Moving
          rssi: drift.Value(-50 - (random % 40)), // -50 to -90
          resetReason: const drift.Value(0),
          uptime: drift.Value(timer.tick),
          isSynced: const drift.Value(false),
        ),
      );

      if (_readingsBuffer.length >= _bufferThreshold) {
        _flushBuffer();
      }
    });
  }

  void _stopSimulation() {
    _isSimulating = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    FileLogger.log("BLE: Stopped Simulation Mode");
    _flushBuffer();
  }

  void dispose() {
    _flushBuffer();
    _bufferTimer?.cancel();
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _simulationTimer?.cancel();
    _connectionStateController.close();
  }
}
