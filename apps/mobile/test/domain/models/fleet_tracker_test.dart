import 'package:flutter_test/flutter_test.dart';
import 'package:last_mile_tracker/domain/models/fleet_tracker.dart';
import 'package:last_mile_tracker/data/database/app_database.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';

void main() {
  group('FleetTracker Model Tests', () {
    final now = DateTime.now();

    test('fromTracker correctly maps all fields', () {
      final tracker = Tracker(
        id: 'device-123',
        name: 'Device 123',
        batteryLevel: 85.5,
        temp: 22.4,
        lastSeen: now,
        isFavorite: true,
        lat: 37.7749,
        lon: -122.4194,
        shockValue: 0,
        status: 'active',
        isSynced: false,
      );

      final shipment = Shipment(
        id: 'shipment-456',
        trackingNumber: 'TRK-789',
        origin: 'Origin',
        destination: 'Destination',
        status: ShipmentStatus.inTransit,
        deviceIds: ['device-123'],
        eta: now,
      );

      final fleetTracker = FleetTracker.fromTracker(
        tracker,
        currentRssi: -65,
        isInRange: true,
        shipment: shipment,
      );

      expect(fleetTracker.id, equals('device-123'));
      expect(fleetTracker.name, equals('Device 123'));
      expect(fleetTracker.batteryLevel, equals(85.5));
      expect(fleetTracker.temp, equals(22.4));
      expect(fleetTracker.rssi, equals(-65));
      expect(fleetTracker.lastSeen, equals(now));
      expect(fleetTracker.isInRange, isTrue);
      expect(fleetTracker.isFavorite, isTrue);
      expect(fleetTracker.shipmentId, equals('shipment-456'));
      expect(fleetTracker.trackingNumber, equals('TRK-789'));
      expect(fleetTracker.lat, equals(37.7749));
      expect(fleetTracker.lon, equals(-122.4194));
      expect(fleetTracker.shockValue, equals(0));
      expect(fleetTracker.status, equals('active'));
    });

    test('copyWith preserves unchanged fields and updates specified ones', () {
      final fleetTracker = FleetTracker(
        id: 'device-123',
        name: 'Device 123',
        lastSeen: now,
        isInRange: false,
      );

      final updated = fleetTracker.copyWith(
        name: 'Updated Device',
        isInRange: true,
      );

      expect(updated.id, equals('device-123'));
      expect(updated.name, equals('Updated Device'));
      expect(updated.lastSeen, equals(now));
      expect(updated.isInRange, isTrue);
    });

    test('lat/lon default to 0 when null', () {
      final fleetTracker = FleetTracker(
        id: 'device-123',
        name: 'Device 123',
        lastSeen: now,
        latitude: null,
        longitude: null,
      );

      expect(fleetTracker.lat, equals(0));
      expect(fleetTracker.lon, equals(0));
    });
  });
}
