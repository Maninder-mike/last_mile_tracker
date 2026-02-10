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

      // Determine version based on length or header
      // V1 is exactly 24 bytes.
      // V2 starts with 0x02 as the first byte if we want to be explicit,
      // but let's check length first for now or header.
      if (bytes.length == 24) {
        return _parseV1(data);
      } else if (bytes.length > 2 && bytes[0] == 2) {
        return _parseV2(bytes);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static SensorReading _parseV1(ByteData data) {
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
  }

  static SensorReading? _parseV2(List<int> bytes) {
    // V2: [Version(1), NumTemps(1), Temp1(2), Temp2(2)...]
    try {
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      int numTemps = data.getUint8(1);

      Map<String, double> temps = {};
      double primaryTemp = 0.0;

      for (int i = 0; i < numTemps; i++) {
        int tRaw = data.getInt16(2 + (i * 2), Endian.little);
        double t = tRaw / 100.0;
        if (i == 0) primaryTemp = t;
        temps['sensor_$i'] = t;
      }

      // Extract batteryDrop (last 2 bytes)
      double? batDrop;
      try {
        int batDropRaw = data.getInt16(2 + (numTemps * 2), Endian.little);
        batDrop = batDropRaw.toDouble();
      } catch (_) {}

      // V2 packets today from firmware only send temps + health in characteristic 0x2A6F
      // For a full reading, we usually merge with V1 or have a full V2.
      // Returning just the temps for now, or a partial reading.
      return SensorReading(
        timestamp: DateTime.now(),
        lat: 0,
        lon: 0,
        speed: 0,
        temp: primaryTemp,
        additionalTemps: temps,
        batteryDrop: batDrop,
        shockValue: 0,
        batteryLevel: 0,
        internalTemp: 0,
        tripState: 0,
        isSynced: false,
      );
    } catch (_) {
      return null;
    }
  }
}
