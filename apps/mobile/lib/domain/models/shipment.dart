import 'package:json_annotation/json_annotation.dart';

part 'shipment.g.dart';

enum ShipmentStatus { inTransit, delivered, delayed, atRisk }

@JsonSerializable()
class Shipment {
  final String id;
  final String trackingNumber;
  final ShipmentStatus status;
  final String origin;
  final String destination;
  final DateTime eta;
  final DateTime? lastUpdate;
  final List<String> deviceIds;

  // Telemetry Snapshot (for list view)
  final double? temperature;
  final Map<String, double> additionalTemps;
  final int? batteryLevel;
  final double? batteryDrop;
  final bool hasAlerts;

  // New Hardware V2 Fields
  final double? latitude;
  final double? longitude;
  final int? shockValue;

  const Shipment({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.origin,
    required this.destination,
    required this.eta,
    this.lastUpdate,
    this.deviceIds = const [],
    this.temperature,
    this.additionalTemps = const {},
    this.batteryLevel,
    this.batteryDrop,
    this.hasAlerts = false,
    this.latitude,
    this.longitude,
    this.shockValue,
  });

  Shipment copyWith({
    String? id,
    String? trackingNumber,
    ShipmentStatus? status,
    String? origin,
    String? destination,
    DateTime? eta,
    DateTime? lastUpdate,
    List<String>? deviceIds,
    double? temperature,
    Map<String, double>? additionalTemps,
    int? batteryLevel,
    double? batteryDrop,
    bool? hasAlerts,
    double? latitude,
    double? longitude,
    int? shockValue,
  }) {
    return Shipment(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      eta: eta ?? this.eta,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      deviceIds: deviceIds ?? this.deviceIds,
      temperature: temperature ?? this.temperature,
      additionalTemps: additionalTemps ?? this.additionalTemps,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryDrop: batteryDrop ?? this.batteryDrop,
      hasAlerts: hasAlerts ?? this.hasAlerts,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      shockValue: shockValue ?? this.shockValue,
    );
  }

  factory Shipment.fromJson(Map<String, dynamic> json) =>
      _$ShipmentFromJson(json);
  Map<String, dynamic> toJson() => _$ShipmentToJson(this);

  // Mock Factory
  static List<Shipment> get mockData => [
    Shipment(
      id: 'shp_001',
      trackingNumber: 'TRK-8821-X',
      status: ShipmentStatus.atRisk,
      origin: 'San Francisco, CA',
      destination: 'Austin, TX',
      eta: DateTime.now().add(const Duration(days: 2)),
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 15)),
      temperature: 8.2, // Too high?
      additionalTemps: {'Probe 2': 7.8, 'Probe 3': 8.5},
      batteryLevel: 45,
      batteryDrop: 120, // mV
      hasAlerts: true,
      deviceIds: ['dev_001'],
      shockValue: 125, // Mock shock
      latitude: 37.7749, // SF
      longitude: -122.4194, // SF
    ),
    Shipment(
      id: 'shp_002',
      trackingNumber: 'TRK-9002-A',
      status: ShipmentStatus.inTransit,
      origin: 'New York, NY',
      destination: 'Chicago, IL',
      eta: DateTime.now().add(const Duration(days: 1)),
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 5)),
      temperature: 4.0,
      additionalTemps: {'Probe 2': 4.1},
      batteryLevel: 88,
      batteryDrop: 45,
      deviceIds: ['dev_002'],
    ),
    Shipment(
      id: 'shp_003',
      trackingNumber: 'TRK-1120-Z',
      status: ShipmentStatus.delayed,
      origin: 'Miami, FL',
      destination: 'Seattle, WA',
      eta: DateTime.now().add(const Duration(days: 5)),
      lastUpdate: DateTime.now().subtract(const Duration(hours: 2)),
      temperature: 3.8,
      batteryLevel: 22,
      deviceIds: ['dev_003'],
    ),
    Shipment(
      id: 'shp_004',
      trackingNumber: 'TRK-3321-B',
      status: ShipmentStatus.delivered,
      origin: 'Los Angeles, CA',
      destination: 'San Diego, CA',
      eta: DateTime.now().subtract(const Duration(hours: 4)),
      lastUpdate: DateTime.now().subtract(const Duration(hours: 4)),
      temperature: 4.1,
      batteryLevel: 10,
      deviceIds: ['dev_004'],
    ),
  ];
}
