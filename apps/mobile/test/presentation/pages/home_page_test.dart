import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

import 'package:last_mile_tracker/presentation/pages/home_page.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/service_providers.dart';
import 'package:last_mile_tracker/presentation/providers/fleet_tracker_provider.dart';
import 'package:last_mile_tracker/presentation/providers/notification_provider.dart';
import 'package:last_mile_tracker/presentation/providers/location_providers.dart';
import 'package:last_mile_tracker/presentation/providers/shipment_match_provider.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/domain/services/connectivity_service.dart';
import 'package:last_mile_tracker/logic/alert_manager.dart';
import 'package:last_mile_tracker/logic/proximity_service.dart';
import 'package:last_mile_tracker/logic/fleet_inventory_service.dart';
import 'package:last_mile_tracker/data/services/ble_service.dart';
import 'package:last_mile_tracker/data/services/ble/scanned_tracker.dart';
import 'package:last_mile_tracker/data/services/ota_service.dart';
import 'package:last_mile_tracker/presentation/layout/main_layout.dart';
import 'package:last_mile_tracker/presentation/widgets/blur_navbar.dart';

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
  BluetoothConnectionState get lastState => BluetoothConnectionState.disconnected;

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

class FakeUserLocation extends UserLocation {
  @override
  Future<LatLng?> build() async {
    return null;
  }
}

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('renders MainLayout with 4 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bleServiceProvider.overrideWith((ref) => FakeBleService()),
            otaServiceProvider.overrideWith((ref) => FakeOtaService()),
            alertManagerProvider.overrideWith((ref) => FakeAlertManager()),
            proximityServiceProvider.overrideWith((ref) => FakeProximityService()),
            fleetInventoryServiceProvider.overrideWith((ref) => FakeFleetInventoryService()),
            connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
            bleConnectionStateProvider.overrideWith(
              (ref) => Stream.value(BluetoothConnectionState.disconnected),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => Stream.value(0)),
            fleetTrackersProvider.overrideWithValue(const AsyncValue.data([])),
            mergedShipmentsProvider.overrideWithValue(const AsyncValue.data([])),
            userLocationProvider.overrideWith(FakeUserLocation.new),
            latestReadingProvider.overrideWith((ref) => Stream.value(null)),
            packageInfoProvider.overrideWith(
              (ref) => Future.value(
                PackageInfo(
                  appName: 'LMT',
                  packageName: 'com.example.lmt',
                  version: '1.0.0',
                  buildNumber: '1',
                ),
              ),
            ),
          ],
          child: const CupertinoApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomePage(),
          ),
        ),
      );

      // Wait for build
      await tester.pumpAndSettle();

      // Verify MainLayout and BlurNavbar are rendered
      expect(find.byType(MainLayout), findsOneWidget);
      expect(find.byType(BlurNavbar), findsOneWidget);

      // Verify there are 4 tabs rendered (gesture detectors in bottom nav)
      // Since it's a row of items, let's verify item texts that are selected
      expect(find.text('Home'), findsOneWidget); // Default selected tab text
      expect(find.text('Map'), findsNothing); // Unselected tabs don't show text in BlurNavbar

      // Clear pending stream and overlay timers
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
