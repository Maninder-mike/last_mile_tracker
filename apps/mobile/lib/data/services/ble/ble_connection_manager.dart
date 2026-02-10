import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/constants/ble_constants.dart';
import '../../../core/utils/file_logger.dart';

class BleConnectionManager {
  final Function(BluetoothConnectionState) onStateChanged;
  final Function(List<int>) onDataReceived;
  final Function(BluetoothCharacteristic, BluetoothCharacteristic)
  onOtaCharsFound;
  final Function() onDisconnected;

  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _characteristicSubscription;

  BluetoothDevice? _device;
  BluetoothDevice? get device => _device;
  BluetoothCharacteristic? _wifiChar;

  int _reconnectDelaySeconds = BleConstants.initialReconnectDelay.inSeconds;

  BleConnectionManager({
    required this.onStateChanged,
    required this.onDataReceived,
    required this.onOtaCharsFound,
    required this.onDisconnected,
  });

  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    try {
      await device.connect();
      FileLogger.log("ConnectionManager: Connected to ${device.platformName}");
      _reconnectDelaySeconds = BleConstants.initialReconnectDelay.inSeconds;

      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((state) {
        onStateChanged(state);

        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnectionResources();
          FileLogger.log(
            "ConnectionManager: Disconnected. Next retry in $_reconnectDelaySeconds s...",
          );
          onDisconnected();

          _reconnectDelaySeconds = (_reconnectDelaySeconds * 2).clamp(
            BleConstants.initialReconnectDelay.inSeconds,
            BleConstants.maxReconnectDelay.inSeconds,
          );
        }
      });

      await _discoverServices(device);
    } catch (e) {
      FileLogger.log("ConnectionManager: Connection error: $e");
      _cleanupConnectionResources();
      onDisconnected();
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    BluetoothCharacteristic? otaControl;
    BluetoothCharacteristic? otaData;

    for (var service in services) {
      final uuid = service.uuid.toString().toUpperCase();

      // Environmental Sensing Service (for live data)
      if (uuid.contains(BleConstants.serviceUuid)) {
        FileLogger.log("ConnectionManager: Found Service ${service.uuid}");
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            await _characteristicSubscription?.cancel();
            _characteristicSubscription = characteristic.lastValueStream.listen(
              (value) {
                onDataReceived(value);
              },
            );
            FileLogger.log(
              "ConnectionManager: Subscribed to ${characteristic.uuid}",
            );
          }
        }
      }

      // Check for OTA characteristics
      for (var characteristic in service.characteristics) {
        final charUuid = characteristic.uuid.toString().toUpperCase();
        if (charUuid == BleConstants.otaControlUuid.toUpperCase()) {
          otaControl = characteristic;
          FileLogger.log("ConnectionManager: Found OTA Control characteristic");
        } else if (charUuid == BleConstants.otaDataUuid.toUpperCase()) {
          otaData = characteristic;
          FileLogger.log("ConnectionManager: Found OTA Data characteristic");
        } else if (charUuid == BleConstants.wifiConfigUuid.toUpperCase()) {
          _wifiChar = characteristic;
          FileLogger.log("ConnectionManager: Found WiFi Config characteristic");
        }
      }
    }

    if (otaControl != null && otaData != null) {
      onOtaCharsFound(otaControl, otaData);
    }
  }

  Future<void> writeWifiConfig(String ssid, String password) async {
    if (_wifiChar == null) {
      throw Exception("WiFi Config characteristic not found");
    }

    final config = "$ssid:$password";
    final data = List<int>.from(config.codeUnits);
    await _wifiChar!.write(data);
    FileLogger.log("ConnectionManager: Wrote WiFi config for $ssid");
  }

  void _cleanupConnectionResources() {
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
  }

  Future<void> disconnect() async {
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    await _device?.disconnect();
    _cleanupConnectionResources();
    _device = null;
  }

  void dispose() {
    disconnect();
  }
}
