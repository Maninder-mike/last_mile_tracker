import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:last_mile_tracker/l10n/app_localizations.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/add_shipment_page.dart';
import 'package:last_mile_tracker/presentation/providers/supabase_providers.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/network_provider.dart';
import 'package:last_mile_tracker/data/services/supabase_service.dart';
import 'package:last_mile_tracker/data/services/ble_service.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';

class FakeSupabaseService extends Fake implements SupabaseService {
  final List<Shipment> createdShipments = [];
  Completer<void>? createCompleter;

  @override
  Future<void> createShipment(Shipment shipment) async {
    if (createCompleter != null) {
      await createCompleter!.future;
    }
    createdShipments.add(shipment);
  }
}

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
  BluetoothDevice? get connectedDevice => null;
}

void main() {
  late FakeSupabaseService fakeSupabaseService;

  setUp(() {
    fakeSupabaseService = FakeSupabaseService();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        supabaseServiceProvider.overrideWithValue(fakeSupabaseService),
        connectivityProvider.overrideWithValue(
          const AsyncValue.data([ConnectivityResult.wifi]),
        ),
        bleServiceProvider.overrideWith((ref) => FakeBleService()),
        bleConnectionStateProvider.overrideWith(
          (ref) => Stream.value(BluetoothConnectionState.disconnected),
        ),
      ],
      child: const CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddShipmentPage(),
      ),
    );
  }

  testWidgets('AddShipmentPage renders all form fields and header', (
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

    // Verify title in header
    expect(find.text('Add Shipment'), findsOneWidget);

    // Verify section headers
    expect(find.text('SHIPMENT IDENTITY'), findsOneWidget);
    expect(find.text('ROUTE INFORMATION'), findsOneWidget);
    expect(find.text('LOGISTICS TIMELINE'), findsOneWidget);

    // Verify input fields by placeholder or label text
    expect(find.text('TRACKING #'), findsOneWidget);
    expect(find.text('ORIGIN'), findsOneWidget);
    expect(find.text('DESTINATION'), findsOneWidget);
    expect(find.text('Estimated Arrival'), findsOneWidget);

    // Verify create button
    expect(find.text('CREATE SHIPMENT'), findsOneWidget);
  });

  testWidgets('Input fields handle text entry and save flow works', (
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

    // Enter tracking number
    await tester.enterText(
      find.widgetWithText(CupertinoTextField, 'Enter Tracking Number'),
      'TRK12345',
    );

    // Enter origin
    await tester.enterText(
      find.widgetWithText(CupertinoTextField, 'Origin City / Hub'),
      'New York',
    );

    // Enter destination
    await tester.enterText(
      find.widgetWithText(CupertinoTextField, 'Destination City / Final Hub'),
      'Los Angeles',
    );

    await tester.pump();

    // Tap the Estimated Arrival card to open date picker
    await tester.tap(find.text('Estimated Arrival'));
    await tester.pumpAndSettle();

    // Verify date picker modal is shown (Confirm Date button is visible)
    expect(find.text('CONFIRM DATE'), findsOneWidget);

    // Tap confirm date to close it
    await tester.tap(find.text('CONFIRM DATE'));
    await tester.pumpAndSettle();

    final completer = Completer<void>();
    fakeSupabaseService.createCompleter = completer;

    // Tap Create Shipment
    await tester.tap(find.text('CREATE SHIPMENT'));
    // Since createShipment is async, pump to allow saving progress indicator
    await tester.pump();
    expect(find.text('CREATING...'), findsOneWidget);

    // Complete the save operation
    completer.complete();
    // Wait for saving to complete and navigation/pop to finish
    await tester.pumpAndSettle();

    // Verify shipment was saved
    expect(fakeSupabaseService.createdShipments.length, 1);
    expect(
      fakeSupabaseService.createdShipments.first.trackingNumber,
      'TRK12345',
    );
    expect(fakeSupabaseService.createdShipments.first.origin, 'New York');
    expect(
      fakeSupabaseService.createdShipments.first.destination,
      'Los Angeles',
    );
  });

  testWidgets('Shows alert dialog when fields are missing', (
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

    // Tap Create Shipment without entering text
    await tester.tap(find.text('CREATE SHIPMENT'));
    await tester.pumpAndSettle();

    // Verify alert dialog shows up
    expect(find.text('Required Fields'), findsOneWidget);
    expect(find.text('Please fill in all shipment details.'), findsOneWidget);

    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Verify dialog is closed
    expect(find.text('Required Fields'), findsNothing);
  });
}
