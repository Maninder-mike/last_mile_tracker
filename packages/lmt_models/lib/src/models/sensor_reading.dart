import 'package:json_annotation/json_annotation.dart';

part 'sensor_reading.g.dart';

@JsonSerializable()
class SensorReading {
  final int? id;
  final DateTime timestamp;

  // GPS Data
  final double lat;
  final double lon;
  final double speed;

  // Sensors
  final double temp;
  final int shockValue;
  final double batteryLevel;
  final int tripState;
  final double internalTemp;

  // Diagnostics
  final int? rssi;
  final int? resetReason;
  final int? uptime;
  final String? wifiSsid;
  final int? wifiSignal;

  // Sync Status
  final bool isSynced;
  final DateTime? syncedAt;

  SensorReading({
    this.id,
    required this.timestamp,
    required this.lat,
    required this.lon,
    required this.speed,
    required this.temp,
    required this.shockValue,
    required this.batteryLevel,
    required this.tripState,
    required this.internalTemp,
    this.rssi,
    this.resetReason,
    this.uptime,
    this.wifiSsid,
    this.wifiSignal,
    this.isSynced = false,
    this.syncedAt,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) =>
      _$SensorReadingFromJson(json);
  Map<String, dynamic> toJson() => _$SensorReadingToJson(this);
}
