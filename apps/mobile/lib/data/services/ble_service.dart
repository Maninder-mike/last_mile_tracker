import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:last_mile_tracker/core/constants/ble_constants.dart';
import 'package:last_mile_tracker/data/database/app_database.dart' as db;
import 'package:last_mile_tracker/data/database/daos/sensor_dao.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';
import 'package:drift/drift.dart' as drift;
import 'package:lmt_models/lmt_models.dart' as models;

import 'ble/ble_scanner.dart';
import 'ble/scanned_tracker.dart';
import 'ble/ble_connection_manager.dart';
import 'ble/ble_ota_manager.dart';
import 'ble/sensor_data_parser.dart';
import 'ble/ble_simulation_service.dart';

class BleService {
  final SensorDao _sensorDao;

  late final BleScanner _scanner;
  late final BleConnectionManager _connectionManager;
  late final BleOtaManager _otaManager;
  late final BleSimulationService _simulationService;

  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState =>
      _connectionStateController.stream;

  final _simulationStateController = StreamController<bool>.broadcast();
  Stream<bool> get simulationState => _simulationStateController.stream;

  BluetoothConnectionState _lastState = BluetoothConnectionState.disconnected;
  BluetoothConnectionState get lastState => _lastState;

  final _liveTelemetryController =
      StreamController<models.SensorReading>.broadcast();
  Stream<models.SensorReading> get liveTelemetry =>
      _liveTelemetryController.stream;

  BluetoothDevice? get connectedDevice => _connectionManager.device;
  final Set<String> _approvedDeviceIds = {};
  bool _isAutoConnectEnabled = true;

  bool get isScanning => _scanner.isScanning;
  Stream<List<ScannedTracker>> get discoveredDevices =>
      _scanner.discoveredDevices;
  bool get simulationActive => _simulationService.isSimulating;

  // Firmware version from connected device
  final _firmwareVersionController = StreamController<String?>.broadcast();
  Stream<String?> get firmwareVersionStream =>
      _firmwareVersionController.stream;
  String? _deviceFirmwareVersion;
  String? get deviceFirmwareVersion => _deviceFirmwareVersion;

  // Data buffering for high-frequency sensor readings
  final List<db.SensorReadingsCompanion> _readingsBuffer = [];
  Timer? _bufferTimer;

  BleService(this._sensorDao) {
    _scanner = BleScanner();

    _connectionManager = BleConnectionManager(
      onStateChanged: (state) {
        _lastState = state;
        _connectionStateController.add(state);
      },
      onDataReceived: (bytes) => _handleRawData(bytes),
      onOtaCharsFound: (control, data) {
        _otaManager.setCharacteristics(control, data);
        // Read firmware version after chars are discovered
        _readDeviceFirmwareVersion();
      },
      onDisconnected: () => _scanner.start(),
    );

    _otaManager = BleOtaManager();
    _simulationService = BleSimulationService(
      onReadingGenerated: (reading) => _bufferReading(reading),
    );

    _startBufferTimer();
    _setupWifiStreams();
    _initAutoConnect();
    _setupAutoConnectListener();
  }

  Future<void> _readDeviceFirmwareVersion() async {
    try {
      final version = await _otaManager.readFirmwareVersion();
      _deviceFirmwareVersion = version;
      _firmwareVersionController.add(version);
      FileLogger.log('BLE: Device firmware version: $version');
    } catch (e) {
      FileLogger.log('BLE: Failed to read firmware version: $e');
    }
  }

  Future<void> _initAutoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('approved_device_ids') ?? [];
    _approvedDeviceIds.addAll(list);
    FileLogger.log(
      "BLE: Loaded ${_approvedDeviceIds.length} approved device IDs.",
    );
  }

  void _setupAutoConnectListener() {
    discoveredDevices.listen((devices) {
      if (!_isAutoConnectEnabled || _approvedDeviceIds.isEmpty) return;
      if (_lastState != BluetoothConnectionState.disconnected) return;

      for (final tracker in devices) {
        if (_approvedDeviceIds.contains(tracker.device.remoteId.str)) {
          FileLogger.log(
            "BLE: Auto-connecting to approved device: ${tracker.device.remoteId.str}",
          );
          connect(tracker.device);
          break;
        }
      }
    });
  }

  // WiFi Streams
  final _wifiScanResultsController =
      StreamController<List<WifiScanResult>>.broadcast();
  final _isWifiScanningController = StreamController<bool>.broadcast();

  StreamSubscription? _cmWifiSub;
  StreamSubscription? _simWifiSub;
  StreamSubscription? _cmScanSub;
  StreamSubscription? _simScanSub;

  void _setupWifiStreams() {
    _cmWifiSub = _connectionManager.wifiScanResults.listen((results) {
      if (!simulationActive) _wifiScanResultsController.add(results);
    });

    _simWifiSub = _simulationService.wifiScanResults.listen((results) {
      if (simulationActive) _wifiScanResultsController.add(results);
    });

    _cmScanSub = _connectionManager.isWifiScanning.listen((isScanning) {
      if (!simulationActive) _isWifiScanningController.add(isScanning);
    });

    _simScanSub = _simulationService.isWifiScanning.listen((isScanning) {
      if (simulationActive) _isWifiScanningController.add(isScanning);
    });
  }

  void _handleRawData(List<int> bytes) {
    final reading = SensorDataParser.parse(bytes);
    if (reading != null) {
      _liveTelemetryController.add(reading);
      _bufferReading(reading);
    }
  }

  void _bufferReading(models.SensorReading reading) {
    final companion = db.SensorReadingsCompanion(
      timestamp: drift.Value(reading.timestamp),
      lat: drift.Value(reading.lat),
      lon: drift.Value(reading.lon),
      speed: drift.Value(reading.speed),
      temp: drift.Value(reading.temp),
      shockValue: drift.Value(reading.shockValue),
      batteryLevel: drift.Value(reading.batteryLevel),
      internalTemp: drift.Value(reading.internalTemp),
      tripState: drift.Value(reading.tripState),
      additionalTemps: drift.Value(
        reading.additionalTemps.isNotEmpty
            ? jsonEncode(reading.additionalTemps)
            : null,
      ),
      batteryDrop: drift.Value(reading.batteryDrop),
      rssi: drift.Value(reading.rssi),
      resetReason: drift.Value(reading.resetReason),
      uptime: drift.Value(reading.uptime),
      isSynced: drift.Value(reading.isSynced),
    );

    _readingsBuffer.add(companion);

    if (_readingsBuffer.length >= BleConstants.bufferThreshold) {
      _flushBuffer();
    }
  }

  void _startBufferTimer() {
    _bufferTimer?.cancel();
    _bufferTimer = Timer.periodic(BleConstants.bufferFlushInterval, (_) {
      _flushBuffer();
    });
  }

  Future<void> _flushBuffer() async {
    if (_readingsBuffer.isEmpty) return;

    final batch = List<db.SensorReadingsCompanion>.from(_readingsBuffer);
    _readingsBuffer.clear();

    try {
      await _sensorDao.insertReadingsBatch(batch);
      FileLogger.log("BLE: Flushed ${batch.length} readings to DB.");
    } catch (e) {
      FileLogger.log("BLE: Buffer flush error: $e");
      _readingsBuffer.addAll(batch);
    }
  }

  Future<void> startScanning() => _scanner.start();

  Future<void> connect(BluetoothDevice device) async {
    await _connectionManager.connect(device);

    // Save to approved devices list on successful connection
    final prefs = await SharedPreferences.getInstance();
    _approvedDeviceIds.add(device.remoteId.str);
    await prefs.setStringList(
      'approved_device_ids',
      _approvedDeviceIds.toList(),
    );
    FileLogger.log("BLE: Added ${device.remoteId.str} to approved devices.");
  }

  bool isApproved(String deviceId) => _approvedDeviceIds.contains(deviceId);

  void setAutoConnect(bool enabled) {
    _isAutoConnectEnabled = enabled;
  }

  Future<void> writeWifiConfig(String ssid, String password) async {
    await _connectionManager.writeWifiConfig(ssid, password);
  }

  Future<void> configureWiFiOta({
    required String owner,
    required String repo,
    int interval = 86400,
  }) async {
    final command = '${BleConstants.otaPrefix}$owner:$repo:$interval';
    await _connectionManager.writeRawConfig(command);
  }

  Stream<List<WifiScanResult>> get wifiScanResults =>
      _wifiScanResultsController.stream;

  Stream<bool> get isWifiScanning => _isWifiScanningController.stream;
  Stream<String> get wifiStatus => _connectionManager.wifiStatus;

  Future<void> scanForWifi() async {
    if (simulationActive) {
      return _simulationService.scanForWifi();
    }
    return _connectionManager.scanForWifi();
  }

  Future<void> identifyDevice() => _connectionManager.identifyDevice();
  Future<void> rebootDevice() => _connectionManager.rebootDevice();
  Future<void> resetWifiConfig() => _connectionManager.resetWifiConfig();

  void toggleSimulation() {
    if (_simulationService.isSimulating) {
      _simulationService.stop();
      _flushBuffer();
      _simulationStateController.add(false);
    } else {
      _simulationService.start();
      _simulationStateController.add(true);
    }
  }

  Future<void> writeOtaControl(Uint8List data) =>
      _otaManager.writeControl(data);
  Future<void> writeOtaData(Uint8List data) => _otaManager.writeData(data);

  void dispose() {
    _flushBuffer();
    _bufferTimer?.cancel();
    _scanner.dispose();
    _connectionManager.dispose();
    _simulationService.dispose();
    _cmWifiSub?.cancel();
    _simWifiSub?.cancel();
    _cmScanSub?.cancel();
    _simScanSub?.cancel();
    _wifiScanResultsController.close();
    _isWifiScanningController.close();
    _simulationStateController.close();
    _connectionStateController.close();
    _firmwareVersionController.close();
  }
}
