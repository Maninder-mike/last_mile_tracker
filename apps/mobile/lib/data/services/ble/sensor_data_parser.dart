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
    if (bytes.length < BleConstants.packetLength) return null;

    try {
      final data = ByteData.sublistView(Uint8List.fromList(bytes));

      double lat = data.getFloat32(BleConstants.offsetLat, Endian.little);
      double lon = data.getFloat32(BleConstants.offsetLon, Endian.little);
      int speedraw = data.getUint16(BleConstants.offsetSpeed, Endian.little);
      int tempraw = data.getInt16(BleConstants.offsetTemp, Endian.little);
      int shock = data.getUint16(BleConstants.offsetShock, Endian.little);
      int batMv = data.getUint16(BleConstants.offsetBattery, Endian.little);
      int intTempRaw = data.getInt16(
        BleConstants.offsetInternalTemp,
        Endian.little,
      );
      int tripState = data.getUint8(BleConstants.offsetTripState);
      int resetReason = data.getUint8(BleConstants.offsetResetReason);
      int uptime = data.getUint32(BleConstants.offsetUptime, Endian.little);

      return SensorReading(
        timestamp: DateTime.now(),
        lat: lat,
        lon: lon,
        speed: speedraw / BleConstants.multiplierSpeed,
        temp: tempraw / BleConstants.multiplierTemp,
        shockValue: shock,
        batteryLevel: batMv / BleConstants.multiplierBattery,
        internalTemp: intTempRaw / BleConstants.multiplierTemp,
        tripState: tripState,
        resetReason: resetReason,
        uptime: uptime,
        isSynced: false,
      );
    } catch (_) {
      return null;
    }
  }
}
