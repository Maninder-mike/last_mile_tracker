import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';

/// Aggregated stats for shipment statuses
class ShipmentStats {
  final int total;
  final int inTransit;
  final int delivered;
  final int delayed;
  final int atRisk;

  const ShipmentStats({
    required this.total,
    required this.inTransit,
    required this.delivered,
    required this.delayed,
    required this.atRisk,
  });
}

final shipmentStatsProvider = Provider<ShipmentStats>((ref) {
  // Use mock data for now, or real data if available from trackers
  final shipments = Shipment.mockData;

  return ShipmentStats(
    total: shipments.length,
    inTransit: shipments
        .where((s) => s.status == ShipmentStatus.inTransit)
        .length,
    delivered: shipments
        .where((s) => s.status == ShipmentStatus.delivered)
        .length,
    delayed: shipments.where((s) => s.status == ShipmentStatus.delayed).length,
    atRisk: shipments.where((s) => s.status == ShipmentStatus.atRisk).length,
  );
});

/// Device health overview
class DeviceHealthStats {
  final int totalDevices;
  final int lowBattery; // < 20%
  final int criticalTemp; // > 10°C or outside range
  final List<double> batteryLevels;

  const DeviceHealthStats({
    required this.totalDevices,
    required this.lowBattery,
    required this.criticalTemp,
    required this.batteryLevels,
  });
}

final deviceHealthStatsProvider = Provider<DeviceHealthStats>((ref) {
  // This would aggregate actual connected device data in a real app
  final batteryLevels = [85.0, 42.0, 15.0, 92.0, 64.0, 18.0, 77.0];

  return DeviceHealthStats(
    totalDevices: batteryLevels.length,
    lowBattery: batteryLevels.where((b) => b < 20).length,
    criticalTemp: 1, // Mock
    batteryLevels: batteryLevels,
  );
});
