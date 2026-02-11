import 'dart:typed_data';
import 'package:lmt_models/lmt_models.dart';
import 'package:last_mile_tracker/core/constants/ble_constants.dart';

class SensorDataParser {
  /// Decodes a 24-byte packet from the Last Mile Tracker BLE characteristic.
  ///
  /// Packet Structure (Little Endian):
  /// [0-3]   float32  lat
  /// [4-7]   float32  lon
  /// [8-9]   uint16   speed (raw: km/h * 100)
  /// [10-11] int16    temp (raw: C * 100)
  /// [12-13] uint16   shock
  /// [14-15] uint16   battery (mV)
  /// [16-17] int16    internalTemp (raw: C * 100)
  /// [18]    uint8    tripState
  /// [19]    uint8    resetReason
  /// [20-23] uint32   uptime (seconds)
  static SensorReading? parse(List<int> bytes) {
    if (bytes.isEmpty) return null;

    try {
      final data = ByteData.sublistView(Uint8List.fromList(bytes));

      // Packet version determines format
      if (bytes.length == BleConstants.packetLength) {
        return _parseV1(data);
      } else if (bytes.length > 0 && bytes[0] == 2) {
        return _parseV2(bytes, data);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static SensorReading _parseV1(ByteData data) {
    // Structure: <ffffHHHBBH
    double lat = data.getFloat32(BleConstants.offsetLat, Endian.little);
    double lon = data.getFloat32(BleConstants.offsetLon, Endian.little);
    double speed = data.getFloat32(BleConstants.offsetSpeed, Endian.little);
    double temp = data.getFloat32(BleConstants.offsetTemp, Endian.little);

    int shock = data.getUint16(BleConstants.offsetShock, Endian.little);
    int batMv = data.getUint16(BleConstants.offsetBattery, Endian.little);
    int intTempRaw = data.getUint16(
      BleConstants.offsetInternalTemp,
      Endian.little,
    );

    int tripState = data.getUint8(BleConstants.offsetTripState);
    int resetReason = data.getUint8(BleConstants.offsetResetReason);
    int uptime = data.getUint16(BleConstants.offsetUptime, Endian.little);

    return SensorReading(
      timestamp: DateTime.now(),
      lat: lat,
      lon: lon,
      speed: speed,
      temp: temp,
      shockValue: shock,
      batteryLevel: batMv / 1000.0, // Convert mV to V (approx)
      internalTemp: intTempRaw.toDouble(),
      tripState: tripState,
      resetReason: resetReason,
      uptime: uptime,
      isSynced: false,
    );
  }

  static SensorReading? _parseV2(List<int> bytes, ByteData data) {
    // Header: [2, num_temps]
    if (bytes.length < 4) return null; // Minimum header + bat_drop

    int numTemps = bytes[1];
    Map<String, double> extraTemps = {};

    int offset = 2;
    for (int i = 0; i < numTemps; i++) {
      if (offset + 2 > bytes.length) break;
      int valRaw = data.getInt16(offset, Endian.little);
      extraTemps['T${i + 2}'] = valRaw / 100.0;
      offset += 2;
    }

    double batteryDrop = 0;
    if (offset + 2 <= bytes.length) {
      int dropRaw = data.getInt16(offset, Endian.little);
      batteryDrop = dropRaw / 1000.0;
    }

    return SensorReading(
      timestamp: DateTime.now(),
      lat: 0,
      lon: 0,
      speed: 0,
      temp: 0,
      additionalTemps: extraTemps,
      batteryLevel: 0,
      shockValue: 0,
      tripState: 0,
      internalTemp: 0,
      batteryDrop: batteryDrop,
      rssi: 0,
      uptime: 0,
      isSynced: false,
    );
  }
}
