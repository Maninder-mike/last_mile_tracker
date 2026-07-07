import 'dart:async';
import 'dart:convert';
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
  StreamSubscription? _otaSubscription;

  BluetoothDevice? _device;
  BluetoothDevice? get device => _device;
  BluetoothCharacteristic? _wifiChar;

  int _reconnectDelaySeconds = BleConstants.initialReconnectDelay.inSeconds;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  BleConnectionManager({
    required this.onStateChanged,
    required this.onDataReceived,
    required this.onOtaCharsFound,
    required this.onDisconnected,
  });

  Future<void> connect(BluetoothDevice device) async {
    if (_isConnecting) {
      FileLogger.log("ConnectionManager: Connection already in progress. Skipping connect request.");
      return;
    }
    if (_device != null && _connectionState == BluetoothConnectionState.connected) {
      FileLogger.log("ConnectionManager: Already connected to ${_device!.platformName}. Skipping connect request.");
      return;
    }

    _isConnecting = true;
    _device = device;

    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        license: License.nonprofit,
      );
      FileLogger.log("ConnectionManager: Connected to ${device.platformName}");
      _reconnectDelaySeconds = BleConstants.initialReconnectDelay.inSeconds;
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((state) {
        _connectionState = state;
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

      // Request a larger MTU after service discovery has finished and connection settled
      Future.microtask(() async {
        try {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (_device == device) {
            final mtu = await device.requestMtu(256);
            FileLogger.log("ConnectionManager: Negotiated MTU: $mtu");
          }
        } catch (e) {
          FileLogger.log("ConnectionManager: MTU negotiation failed: $e");
        }
      });
    } catch (e) {
      FileLogger.log("ConnectionManager: Connection error: $e. Forcing disconnect cleanup.");
      _connectionState = BluetoothConnectionState.disconnected;
      onStateChanged(BluetoothConnectionState.disconnected);
      try {
        await device.disconnect();
      } catch (discErr) {
        FileLogger.log("ConnectionManager: Disconnect cleanup error: $discErr");
      }
      _cleanupConnectionResources();
      onDisconnected();
    } finally {
      _isConnecting = false;
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

  final _otaNotificationController = StreamController<String>.broadcast();
  Stream<String> get otaNotificationStream => _otaNotificationController.stream;

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
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            await _otaSubscription?.cancel();
            _otaSubscription = characteristic.onValueReceived.listen((value) {
              _handleOtaNotification(value);
            });
            FileLogger.log("ConnectionManager: Subscribed to OTA Control");
          }
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

  void _handleOtaNotification(List<int> value) {
    try {
      final message = String.fromCharCodes(value).trim();
      FileLogger.log("ConnectionManager: Received OTA Notification: $message");
      _otaNotificationController.add(message);
    } catch (e) {
      FileLogger.log("ConnectionManager: Error parsing OTA notification: $e");
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
    final payload = jsonEncode({'ssid': ssid, 'pass': password});
    await writeRawConfig(payload);
  }

  Future<void> writeRawConfig(String command) async {
    if (_wifiChar == null) {
      throw Exception("WiFi Config characteristic not found");
    }

    final data = List<int>.from(command.codeUnits);
    try {
      await _wifiChar!.write(data);
      FileLogger.log("ConnectionManager: Wrote config command: $command");
    } catch (e) {
      final errorStr = e.toString();
      FileLogger.log("ConnectionManager: Error writing config command '$command': $errorStr");

      // In production, when the mobile app sends commands like WiFi Config (SSID:Password),
      // Scan, or Reboot to the tracker, the device might switch radio modes, reboot, or
      // disconnect immediately. This can cause the Android/iOS BLE stack to throw a GATT error
      // (like GATT_ERROR status 133) because the write ACK packet is not received.
      // If the error indicates a GATT status/timeout write issue, and the device has disconnected,
      // we suppress the exception and return success, as the command was successfully processed by the tracker.
      final isGattOrWriteError = errorStr.contains('133') || 
                                 errorStr.toUpperCase().contains('GATT') || 
                                 errorStr.contains('status') ||
                                 errorStr.contains('writeCharacteristic');
      
      if (isGattOrWriteError) {
        // Wait briefly for the connection state to update in the Bluetooth stack
        await Future.delayed(const Duration(milliseconds: 600));
        if (_connectionState == BluetoothConnectionState.disconnected || _device == null) {
          FileLogger.log("ConnectionManager: Suppressed write error. Device disconnected as expected after command: $command");
          return;
        }
      }
      rethrow;
    }
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
    _otaSubscription?.cancel();
    _otaSubscription = null;
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
    _otaNotificationController.close();
  }
}

class WifiScanResult {
  final String ssid;
  final int rssi;

  WifiScanResult(this.ssid, this.rssi);
}
