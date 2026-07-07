import 'package:lmt_models/lmt_models.dart' as models;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/l10n/app_localizations.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/shipment_detail_page.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/service_providers.dart';
import 'package:last_mile_tracker/presentation/providers/notification_provider.dart';
import 'package:last_mile_tracker/data/services/ble_service.dart';
import 'package:last_mile_tracker/data/services/ble/scanned_tracker.dart';
import 'package:last_mile_tracker/data/services/ota_service.dart';
import 'package:last_mile_tracker/logic/alert_manager.dart';
import 'package:last_mile_tracker/logic/proximity_service.dart';
import 'package:last_mile_tracker/logic/fleet_inventory_service.dart';
import 'package:last_mile_tracker/domain/services/connectivity_service.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';

// Fake implementations using standard Dart `Fake`
class FakeBleService extends Fake implements BleService {
  @override
  String? get deviceFirmwareVersion => '1.0.0';
  @override
  Future<void> startScanning() async {}
  @override
  Stream<BluetoothConnectionState> get connectionState =>
      Stream.value(BluetoothConnectionState.disconnected);
  @override
  BluetoothConnectionState get lastState =>
      BluetoothConnectionState.disconnected;
  @override
  Stream<List<ScannedTracker>> get discoveredDevices => Stream.value([]);
  @override
  BluetoothDevice? get connectedDevice => null;
  @override
  bool get simulationActive => false;
  @override
  void dispose() {}
}

class FakeOtaService extends Fake implements OtaService {
  @override
  Future<FirmwareRelease?> checkForUpdate({
    bool isAutoCheck = false,
    String? deviceFirmwareVersion,
  }) async {
    return null;
  }

  @override
  void dispose() {}
}

class FakeAlertManager extends Fake implements AlertManager {}

class FakeProximityService extends Fake implements ProximityService {}

class FakeFleetInventoryService extends Fake implements FleetInventoryService {}

void main() {
  final testShipment = Shipment(
    id: 'shipment-1',
    trackingNumber: 'LMT-1001',
    status: ShipmentStatus.inTransit,
    origin: 'New York',
    destination: 'Los Angeles',
    eta: DateTime.now().add(const Duration(days: 1)),
    deviceIds: ['device-1'],
    latitude: null,
    longitude: null,
    temperature: 4.5,
    batteryLevel: 85,
  );

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        recentPathProvider.overrideWithValue(const AsyncValue.data([])),
        bleServiceProvider.overrideWith((ref) => FakeBleService()),
        otaServiceProvider.overrideWith((ref) => FakeOtaService()),
        alertManagerProvider.overrideWith((ref) => FakeAlertManager()),
        proximityServiceProvider.overrideWith((ref) => FakeProximityService()),
        fleetInventoryServiceProvider.overrideWith(
          (ref) => FakeFleetInventoryService(),
        ),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
        bleConnectionStateProvider.overrideWith(
          (ref) => Stream.value(BluetoothConnectionState.disconnected),
        ),
        unreadNotificationCountProvider.overrideWith((ref) => Stream.value(0)),
      ],
      child: CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShipmentDetailPage(shipment: testShipment),
      ),
    );
  }

  testWidgets('ShipmentDetailPage renders details cleanly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('LMT-1001', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
    'ShipmentDetailPage renders with valid location and active path',
    (WidgetTester tester) async {
      final shipmentWithLocation = testShipment.copyWith(
        latitude: 37.7749,
        longitude: -122.4194,
      );

      Widget createTestWidgetWithLocation() {
        return ProviderScope(
          overrides: [
            recentPathProvider.overrideWithValue(
              AsyncValue.data([
                models.SensorReading(
                  id: 1,
                  timestamp: DateTime.now(),
                  lat: 37.7749,
                  lon: -122.4194,
                  speed: 10.0,
                  temp: 4.5,
                  shockValue: 120,
                  batteryLevel: 85.0,
                  tripState: 1,
                  internalTemp: 25.0,
                ),
                models.SensorReading(
                  id: 2,
                  timestamp: DateTime.now().add(const Duration(minutes: 5)),
                  lat: 37.7849,
                  lon: -122.4094,
                  speed: 12.0,
                  temp: 4.6,
                  shockValue: 110,
                  batteryLevel: 84.0,
                  tripState: 1,
                  internalTemp: 25.1,
                ),
              ]),
            ),
            bleServiceProvider.overrideWith((ref) => FakeBleService()),
            otaServiceProvider.overrideWith((ref) => FakeOtaService()),
            alertManagerProvider.overrideWith((ref) => FakeAlertManager()),
            proximityServiceProvider.overrideWith(
              (ref) => FakeProximityService(),
            ),
            fleetInventoryServiceProvider.overrideWith(
              (ref) => FakeFleetInventoryService(),
            ),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
            bleConnectionStateProvider.overrideWith(
              (ref) => Stream.value(BluetoothConnectionState.disconnected),
            ),
            unreadNotificationCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: CupertinoApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShipmentDetailPage(shipment: shipmentWithLocation),
          ),
        );
      }

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidgetWithLocation());
      await tester.pumpAndSettle();

      expect(find.text('LMT-1001', skipOffstage: false), findsOneWidget);
    },
  );

  testWidgets(
    'ShipmentDetailPage renders with valid location and loading path',
    (WidgetTester tester) async {
      final shipmentWithLocation = testShipment.copyWith(
        latitude: 37.7749,
        longitude: -122.4194,
      );

      Widget createTestWidgetLoadingPath() {
        return ProviderScope(
          overrides: [
            recentPathProvider.overrideWithValue(const AsyncValue.loading()),
            bleServiceProvider.overrideWith((ref) => FakeBleService()),
            otaServiceProvider.overrideWith((ref) => FakeOtaService()),
            alertManagerProvider.overrideWith((ref) => FakeAlertManager()),
            proximityServiceProvider.overrideWith(
              (ref) => FakeProximityService(),
            ),
            fleetInventoryServiceProvider.overrideWith(
              (ref) => FakeFleetInventoryService(),
            ),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
            bleConnectionStateProvider.overrideWith(
              (ref) => Stream.value(BluetoothConnectionState.disconnected),
            ),
            unreadNotificationCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: CupertinoApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShipmentDetailPage(shipment: shipmentWithLocation),
          ),
        );
      }

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidgetLoadingPath());
      await tester.pumpAndSettle();

      expect(find.text('LMT-1001', skipOffstage: false), findsOneWidget);
    },
  );
}
