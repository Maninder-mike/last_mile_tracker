import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/constants/ble_constants.dart';
import '../../../core/utils/file_logger.dart';

class BleOtaManager {
  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _dataChar;

  void setCharacteristics(
    BluetoothCharacteristic control,
    BluetoothCharacteristic data,
  ) {
    _controlChar = control;
    _dataChar = data;
    FileLogger.log(
      'OTA: Control char properties — '
      'read: ${control.properties.read}, '
      'write: ${control.properties.write}, '
      'writeNoResp: ${control.properties.writeWithoutResponse}, '
      'notify: ${control.properties.notify}',
    );
    FileLogger.log(
      'OTA: Data char properties — '
      'write: ${data.properties.write}, '
      'writeNoResp: ${data.properties.writeWithoutResponse}',
    );
  }

  /// Read the firmware version from the OTA Control characteristic.
  /// The ESP32 writes "FW:x.y.z" to this characteristic on boot.
  Future<String?> readFirmwareVersion() async {
    final char = _controlChar;
    if (char == null) {
      FileLogger.log(
        'OTA: Control characteristic not available for version read.',
      );
      return null;
    }

    try {
      if (!char.properties.read) {
        FileLogger.log('OTA: Control characteristic does not support reading.');
        return null;
      }
      final value = await char.read();
      final raw = String.fromCharCodes(value).trim();
      FileLogger.log('OTA: Read version raw: $raw');

      if (raw.startsWith(BleConstants.firmwareVersionPrefix)) {
        return raw.substring(BleConstants.firmwareVersionPrefix.length);
      }
      return null;
    } catch (e) {
      FileLogger.log('OTA: Failed to read firmware version: $e');
      return null;
    }
  }

  /// Write to OTA Control characteristic (CMD_START, CMD_END)
  Future<void> writeControl(Uint8List data) async {
    final char = _controlChar;
    if (char == null) {
      throw Exception(
        'OTA Control characteristic not found. Reconnect device.',
      );
    }
    // Use withoutResponse if write-with-response is not supported
    final useWithoutResponse =
        !char.properties.write && char.properties.writeWithoutResponse;
    if (!char.properties.write && !char.properties.writeWithoutResponse) {
      throw Exception('OTA Control characteristic does not support writing.');
    }
    try {
      await char.write(data, withoutResponse: useWithoutResponse);
    } catch (e) {
      FileLogger.log(
        'OTA: writeControl failed (withoutResponse=$useWithoutResponse, '
        'write=${char.properties.write}, '
        'writeNoResp=${char.properties.writeWithoutResponse}): $e',
      );
      rethrow;
    }
  }

  /// Write to OTA Data characteristic (CMD_DATA chunks)
  /// Uses write-with-response for reliability — fire-and-forget
  /// (writeWithoutResponse) can silently drop packets, corrupting transfers.
  Future<void> writeData(Uint8List data) async {
    final char = _dataChar;
    if (char == null) {
      throw Exception('OTA Data characteristic not found. Reconnect device.');
    }
    // Prefer write-with-response for guaranteed delivery.
    // Fall back to writeWithoutResponse if the characteristic doesn't support write.
    final useWithoutResponse =
        !char.properties.write && char.properties.writeWithoutResponse;
    await char.write(data, withoutResponse: useWithoutResponse);
  }

  void clear() {
    _controlChar = null;
    _dataChar = null;
  }
}
