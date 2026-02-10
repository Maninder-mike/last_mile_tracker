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
  @JsonKey(defaultValue: {})
  final Map<String, double> additionalTemps;
  final int shockValue;
  final double batteryLevel;
  final int tripState;
  final double internalTemp;
  final double? batteryDrop; // Health metric

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
    this.additionalTemps = const {},
    required this.shockValue,
    required this.batteryLevel,
    required this.tripState,
    required this.internalTemp,
    this.batteryDrop,
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
