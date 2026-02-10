import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lmt_models/lmt_models.dart';

class ScannedTracker {
  final BluetoothDevice device;
  final int rssi;
  final DateTime lastSeen;
  final SensorReading? telemetry;

  String get id => device.remoteId.str;
  String get name => device.platformName;

  const ScannedTracker({
    required this.device,
    required this.rssi,
    required this.lastSeen,
    this.telemetry,
  });

  ScannedTracker copyWith({
    int? rssi,
    DateTime? lastSeen,
    SensorReading? telemetry,
  }) {
    return ScannedTracker(
      device: device,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
      telemetry: telemetry ?? this.telemetry,
    );
  }
}
