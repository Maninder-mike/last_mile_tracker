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
  StreamSubscription? _extCharacteristicSubscription;

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
      await device.connect(license: License.free);
      FileLogger.log("ConnectionManager: Connected to ${device.platformName}");
      _reconnectDelaySeconds = BleConstants.initialReconnectDelay.inSeconds;

      // Request a larger MTU for OTA data transfers
      try {
        final mtu = await device.requestMtu(512);
        FileLogger.log("ConnectionManager: Negotiated MTU: $mtu");
      } catch (e) {
        FileLogger.log("ConnectionManager: MTU negotiation failed: $e");
      }

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

  StreamSubscription? _wifiSubscription;
  final _wifiScanController =
      StreamController<List<WifiScanResult>>.broadcast();
  Stream<List<WifiScanResult>> get wifiScanResults =>
      _wifiScanController.stream;

  final _isWifiScanningController = StreamController<bool>.broadcast();
  Stream<bool> get isWifiScanning => _isWifiScanningController.stream;

  final _wifiStatusController = StreamController<String>.broadcast();
  Stream<String> get wifiStatus => _wifiStatusController.stream;

  final List<WifiScanResult> _currentScanResults = [];

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    BluetoothCharacteristic? otaControl;
    BluetoothCharacteristic? otaData;

    for (var service in services) {
      final serviceUuid = service.uuid.toString().toUpperCase();
      FileLogger.log("ConnectionManager: Found Service $serviceUuid");

      for (var characteristic in service.characteristics) {
        final charUuid = characteristic.uuid.toString().toUpperCase();
        FileLogger.log(
          "ConnectionManager: Checking Characteristic $charUuid (Properties: ${characteristic.properties})",
        );

        // 1. WiFi Config (FF01)
        if (_isUuidMatch(charUuid, BleConstants.wifiConfigUuid)) {
          _wifiChar = characteristic;
          FileLogger.log(
            "ConnectionManager: SUCCESS - Identified WiFi Config Char: $charUuid",
          );
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            await _wifiSubscription?.cancel();
            _wifiSubscription = characteristic.onValueReceived.listen((value) {
              _handleWifiNotification(value);
            });
            FileLogger.log("ConnectionManager: Subscribed to WiFi Results");
          } else {
            FileLogger.log(
              "ConnectionManager: WARNING - WiFi Config Char does NOT support Notify!",
            );
          }
        }
        // 2. Sensor Data (2A6E)
        else if (_isUuidMatch(charUuid, BleConstants.tempCharUuid)) {
          FileLogger.log("ConnectionManager: Identified Sensor Data Char");
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            await _characteristicSubscription?.cancel();
            _characteristicSubscription = characteristic.onValueReceived.listen(
              (value) {
                onDataReceived(value);
              },
            );
            FileLogger.log("ConnectionManager: Subscribed to Sensor Data");
          }
        }
        // 2.5 Extended Sensor Data (2A6F)
        else if (_isUuidMatch(charUuid, BleConstants.extendedTempCharUuid)) {
          FileLogger.log("ConnectionManager: Identified Extended Sensor Char");
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            await _extCharacteristicSubscription?.cancel();
            _extCharacteristicSubscription = characteristic.onValueReceived
                .listen((value) {
                  onDataReceived(value);
                });
            FileLogger.log("ConnectionManager: Subscribed to Extended Sensor");
          }
        }
        // 3. OTA Control (0001)
        else if (_isUuidMatch(charUuid, BleConstants.otaControlUuid)) {
          otaControl = characteristic;
          FileLogger.log("ConnectionManager: Identified OTA Control Char");
        }
        // 4. OTA Data (0002)
        else if (_isUuidMatch(charUuid, BleConstants.otaDataUuid)) {
          otaData = characteristic;
          FileLogger.log("ConnectionManager: Identified OTA Data Char");
        }
      }
    }

    if (otaControl != null && otaData != null) {
      onOtaCharsFound(otaControl, otaData);
    }
  }

  bool _isUuidMatch(String foundUuid, String constantUuid) {
    foundUuid = foundUuid.toUpperCase();
    constantUuid = constantUuid.toUpperCase();

    // Direct match
    if (foundUuid == constantUuid) return true;

    // Short form match (e.g. "FF01" matches "0000FF01-0000-1000-8000-00805F9B34FB")
    if (constantUuid.contains(foundUuid) && foundUuid.length <= 8) return true;

    // 128-bit match ignoring dashes
    if (foundUuid.replaceAll('-', '') == constantUuid.replaceAll('-', '')) {
      return true;
    }

    return false;
  }

  void _handleWifiNotification(List<int> value) {
    try {
      final message = String.fromCharCodes(value).trim();
      FileLogger.log("ConnectionManager: Received WiFi Message: $message");

      if (message == BleConstants.scanEnd) {
        FileLogger.log(
          "ConnectionManager: WiFi Scan complete. Found ${_currentScanResults.length} networks.",
        );
        _isWifiScanningController.add(false);
        return;
      }

      if (message.startsWith(BleConstants.wifiPrefix)) {
        _wifiStatusController.add(message);
        FileLogger.log("ConnectionManager: WiFi Status Update: $message");
        return;
      }

      // Expected format: "SSID,RSSI"
      final parts = message.split(',');
      if (parts.length == 2) {
        final ssid = parts[0];
        final rssi = int.tryParse(parts[1]) ?? -100;

        // Add or update
        final existingIndex = _currentScanResults.indexWhere(
          (r) => r.ssid == ssid,
        );
        if (existingIndex >= 0) {
          _currentScanResults[existingIndex] = WifiScanResult(ssid, rssi);
        } else {
          _currentScanResults.add(WifiScanResult(ssid, rssi));
        }

        // Sort by RSSI
        _currentScanResults.sort((a, b) => b.rssi.compareTo(a.rssi));
        _wifiScanController.add(List.from(_currentScanResults));
      }
    } catch (e) {
      FileLogger.log("ConnectionManager: Error parsing WiFi notification: $e");
    }
  }

  Future<void> scanForWifi() async {
    if (_wifiChar == null) throw Exception("WiFi Characteristic not found");

    _currentScanResults.clear();
    _wifiScanController.add([]);
    _isWifiScanningController.add(true);

    try {
      await _wifiChar!.write(BleConstants.cmdScan.codeUnits);
      FileLogger.log("ConnectionManager: Sent WiFi Scan Command");

      // Timeout safety
      Future.delayed(const Duration(seconds: 15), () {
        _isWifiScanningController.add(false);
      });
    } catch (e) {
      _isWifiScanningController.add(false);
      rethrow;
    }
  }

  Future<void> writeWifiConfig(String ssid, String password) async {
    await writeRawConfig("$ssid:$password");
  }

  Future<void> writeRawConfig(String command) async {
    if (_wifiChar == null) {
      throw Exception("WiFi Config characteristic not found");
    }

    final data = List<int>.from(command.codeUnits);
    await _wifiChar!.write(data);
    FileLogger.log("ConnectionManager: Wrote config command: $command");
  }

  Future<void> identifyDevice() async {
    if (_wifiChar == null) throw Exception("WiFi Characteristic not found");
    await _wifiChar!.write(BleConstants.cmdIdentify.codeUnits);
    FileLogger.log("ConnectionManager: Sent Identify Command");
  }

  Future<void> rebootDevice() async {
    if (_wifiChar == null) throw Exception("WiFi Characteristic not found");
    await _wifiChar!.write(BleConstants.cmdReboot.codeUnits);
    FileLogger.log("ConnectionManager: Sent Reboot Command");
  }

  Future<void> resetWifiConfig() async {
    if (_wifiChar == null) throw Exception("WiFi Characteristic not found");
    await _wifiChar!.write(BleConstants.cmdResetWifi.codeUnits);
    FileLogger.log("ConnectionManager: Sent Reset WiFi Command");
  }

  void _cleanupConnectionResources() {
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    _extCharacteristicSubscription?.cancel();
    _extCharacteristicSubscription = null;
    _wifiSubscription?.cancel();
    _wifiSubscription = null;
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
    _wifiScanController.close();
  }
}

class WifiScanResult {
  final String ssid;
  final int rssi;

  WifiScanResult(this.ssid, this.rssi);
}
