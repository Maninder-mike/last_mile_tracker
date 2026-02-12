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
    await char.write(data, withoutResponse: useWithoutResponse);
  }

  /// Write to OTA Data characteristic (CMD_DATA chunks, without response for speed)
  Future<void> writeData(Uint8List data) async {
    final char = _dataChar;
    if (char == null) {
      throw Exception('OTA Data characteristic not found. Reconnect device.');
    }
    await char.write(data, withoutResponse: true);
  }

  void clear() {
    _controlChar = null;
    _dataChar = null;
  }
}
