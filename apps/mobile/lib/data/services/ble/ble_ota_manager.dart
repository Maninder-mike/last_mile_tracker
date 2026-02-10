import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

  /// Write to OTA Control characteristic (CMD_START, CMD_END)
  Future<void> writeControl(Uint8List data) async {
    final char = _controlChar;
    if (char == null) {
      throw Exception(
        'OTA Control characteristic not found. Reconnect device.',
      );
    }
    await char.write(data, withoutResponse: false);
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
