import 'package:flutter_test/flutter_test.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';

void main() {
  group('Shipment Model Tests', () {
    test('JSON round-trip serialization works correctly', () {
      final shipment = Shipment(
        id: 'shp_999',
        trackingNumber: 'TRK-9999-Z',
        status: ShipmentStatus.inTransit,
        origin: 'Miami, FL',
        destination: 'Seattle, WA',
        eta: DateTime.parse('2026-06-24T12:00:00Z'),
        deviceIds: ['dev_999'],
        temperature: 3.5,
        batteryLevel: 80,
      );

      final json = shipment.toJson();
      final deserialized = Shipment.fromJson(json);

      expect(deserialized.id, equals(shipment.id));
      expect(deserialized.trackingNumber, equals(shipment.trackingNumber));
      expect(deserialized.status, equals(shipment.status));
      expect(deserialized.origin, equals(shipment.origin));
      expect(deserialized.destination, equals(shipment.destination));
      expect(deserialized.eta, equals(shipment.eta));
      expect(deserialized.deviceIds, equals(shipment.deviceIds));
      expect(deserialized.temperature, equals(shipment.temperature));
      expect(deserialized.batteryLevel, equals(shipment.batteryLevel));
    });

    test('copyWith works correctly', () {
      final shipment = Shipment(
        id: 'shp_999',
        trackingNumber: 'TRK-9999-Z',
        status: ShipmentStatus.inTransit,
        origin: 'Miami, FL',
        destination: 'Miami Beach, FL',
        eta: DateTime.parse('2026-06-24T12:00:00Z'),
      );

      final updated = shipment.copyWith(
        status: ShipmentStatus.delivered,
        destination: 'Key West, FL',
      );

      expect(updated.id, equals(shipment.id));
      expect(updated.status, equals(ShipmentStatus.delivered));
      expect(updated.destination, equals('Key West, FL'));
      expect(updated.origin, equals('Miami, FL'));
    });
  });
}
