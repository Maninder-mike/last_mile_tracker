import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';

class MockShipmentsNotifier extends Notifier<List<Shipment>> {
  @override
  List<Shipment> build() {
    return Shipment.mockData;
  }

  void addShipment(Shipment shipment) {
    state = [...state, shipment];
  }

  void toggleFavorite(String deviceId, bool isFavorite) {
    state = [
      for (final s in state)
        if (s.deviceIds.contains(deviceId))
          s.copyWith(isFavorite: !isFavorite)
        else
          s
    ];
  }

  void updateStatus(String id, ShipmentStatus status) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(status: status) else s
    ];
  }
}

final mockShipmentsProvider =
    NotifierProvider<MockShipmentsNotifier, List<Shipment>>(() {
  return MockShipmentsNotifier();
});
