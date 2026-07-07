import 'package:last_mile_tracker/data/database/app_database.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';

class FleetTracker {
  final String id;
  final String name;
  final String? customName;
  final double? batteryLevel;
  final double? temp;
  final int? rssi;
  final DateTime lastSeen;
  final bool isInRange;
  final bool isFavorite;
  final String? shipmentId;
  final String? trackingNumber;
  final double? latitude;
  final double? longitude;
  final int? shockValue;
  final String status;

  const FleetTracker({
    required this.id,
    required this.name,
    this.customName,
    this.batteryLevel,
    this.temp,
    this.rssi,
    required this.lastSeen,
    this.isInRange = false,
    this.isFavorite = false,
    this.shipmentId,
    this.trackingNumber,
    this.latitude,
    this.longitude,
    this.shockValue,
    this.status = 'Unknown',
  });

  String get displayName => (customName != null && customName!.trim().isNotEmpty) ? customName! : name;

  double get lat => latitude ?? 0;
  double get lon => longitude ?? 0;

  factory FleetTracker.fromTracker(
    Tracker tracker, {
    int? currentRssi,
    bool isInRange = false,
    Shipment? shipment,
  }) {
    return FleetTracker(
      id: tracker.id,
      name: tracker.name,
      customName: tracker.customName,
      batteryLevel: tracker.batteryLevel,
      temp: tracker.temp,
      rssi: currentRssi,
      lastSeen: tracker.lastSeen,
      isInRange: isInRange,
      isFavorite: tracker.isFavorite,
      shipmentId: shipment?.id,
      trackingNumber: shipment?.trackingNumber,
      latitude: tracker.lat,
      longitude: tracker.lon,
      shockValue: tracker.shockValue,
      status: tracker.status,
    );
  }

  FleetTracker copyWith({
    String? id,
    String? name,
    String? customName,
    double? batteryLevel,
    double? temp,
    int? rssi,
    DateTime? lastSeen,
    bool? isInRange,
    bool? isFavorite,
    String? shipmentId,
    String? trackingNumber,
    double? latitude,
    double? longitude,
    int? shockValue,
    String? status,
  }) {
    return FleetTracker(
      id: id ?? this.id,
      name: name ?? this.name,
      customName: customName ?? this.customName,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      temp: temp ?? this.temp,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
      isInRange: isInRange ?? this.isInRange,
      isFavorite: isFavorite ?? this.isFavorite,
      shipmentId: shipmentId ?? this.shipmentId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      shockValue: shockValue ?? this.shockValue,
      status: status ?? this.status,
    );
  }
}
