import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lmt_models/lmt_models.dart';

class ScannedTracker {
  final BluetoothDevice device;
  final int rssi;
  final DateTime lastSeen;
  final AdvertisementData? advertisementData;
  final SensorReading? telemetry;

  String get id => device.remoteId.str;
  String get name => device.platformName;

  const ScannedTracker({
    required this.device,
    required this.rssi,
    required this.lastSeen,
    this.advertisementData,
    this.telemetry,
  });

  ScannedTracker copyWith({
    int? rssi,
    DateTime? lastSeen,
    AdvertisementData? advertisementData,
    SensorReading? telemetry,
  }) {
    return ScannedTracker(
      device: device,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
      advertisementData: advertisementData ?? this.advertisementData,
      telemetry: telemetry ?? this.telemetry,
    );
  }
}
