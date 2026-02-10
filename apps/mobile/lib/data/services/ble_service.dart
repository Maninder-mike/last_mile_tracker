import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/core/constants/ble_constants.dart';
import 'package:last_mile_tracker/data/database/app_database.dart' as db;
import 'package:last_mile_tracker/data/database/daos/sensor_dao.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';
import 'package:drift/drift.dart' as drift;
import 'package:lmt_models/lmt_models.dart' as models;

import 'ble/ble_scanner.dart';
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

  BluetoothConnectionState _lastState = BluetoothConnectionState.disconnected;
  BluetoothConnectionState get lastState => _lastState;

  bool get isScanning => _scanner.isScanning;
  Stream<List<ScanResult>> get discoveredDevices => _scanner.discoveredDevices;
  bool get simulationActive => _simulationService.isSimulating;

  // Data buffering for high-frequency sensor readings
  final List<db.SensorReadingsCompanion> _readingsBuffer = [];
  Timer? _bufferTimer;

  BleService(this._sensorDao) {
    _scanner = BleScanner(
      onDeviceFound: (device) => _connectionManager.connect(device),
    );

    _connectionManager = BleConnectionManager(
      onStateChanged: (state) {
        _lastState = state;
        _connectionStateController.add(state);
      },
      onDataReceived: (bytes) => _handleRawData(bytes),
      onOtaCharsFound: (control, data) =>
          _otaManager.setCharacteristics(control, data),
      onDisconnected: () => _scanner.start(),
    );

    _otaManager = BleOtaManager();
    _simulationService = BleSimulationService(
      onReadingGenerated: (reading) => _bufferReading(reading),
    );

    _startBufferTimer();
  }

  void _handleRawData(List<int> bytes) {
    final reading = SensorDataParser.parse(bytes);
    if (reading != null) {
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

  Future<void> connect(BluetoothDevice device) =>
      _connectionManager.connect(device);

  Future<void> writeWifiConfig(String ssid, String password) =>
      _connectionManager.writeWifiConfig(ssid, password);

  void toggleSimulation() {
    if (_simulationService.isSimulating) {
      _simulationService.stop();
      _flushBuffer();
    } else {
      _simulationService.start();
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
    _connectionStateController.close();
  }
}
