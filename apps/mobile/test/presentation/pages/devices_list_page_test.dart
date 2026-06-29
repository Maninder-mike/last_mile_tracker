import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/l10n/app_localizations.dart';
import 'package:last_mile_tracker/presentation/pages/devices/devices_list_page.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/data/database/app_database.dart';
import 'package:last_mile_tracker/data/services/ble_service.dart';

// Fake BleService using standard Dart Fake
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
  BluetoothDevice? get connectedDevice => null;
}

void main() {
  final mockTrackers = [
    Tracker(
      id: 'device-1',
      name: 'Temp Tracker A',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      batteryLevel: 85.0,
      temp: 4.5,
      shockValue: 0,
      status: 'Online',
      isFavorite: true,
      isSynced: true,
    ),
    Tracker(
      id: 'device-2',
      name: 'Ble Sensor B',
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
      batteryLevel: 15.0, // Low battery
      temp: 8.2,
      shockValue: 1,
      status: 'Offline',
      isFavorite: false,
      isSynced: true,
    ),
  ];

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        allTrackersProvider.overrideWithValue(AsyncValue.data(mockTrackers)),
        bleServiceProvider.overrideWith((ref) => FakeBleService()),
        bleConnectionStateProvider.overrideWith(
          (ref) => Stream.value(BluetoothConnectionState.disconnected),
        ),
      ],
      child: const CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DevicesListPage(),
      ),
    );
  }

  testWidgets('DevicesListPage renders search row and filter button', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify search field exists
    expect(find.byType(CupertinoSearchTextField), findsOneWidget);

    // Verify filter icon button exists
    expect(find.byIcon(CupertinoIcons.slider_horizontal_3), findsOneWidget);

    // Verify devices render in the list
    expect(find.text('Temp Tracker A'), findsOneWidget);
    expect(find.text('Ble Sensor B'), findsOneWidget);
  });

  testWidgets('Tapping filter button opens filter modal and filters status', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap the filter button to open sheet
    final filterButton = find.byIcon(CupertinoIcons.slider_horizontal_3);
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    // Verify bottom sheet titles
    expect(find.text('Filter Devices'), findsOneWidget);

    // Tap "Online" status pill
    await tester.tap(find.text('Online'));
    await tester.pump();

    // Tap Apply Filters
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    // Modal should be closed
    expect(find.text('Filter Devices'), findsNothing);

    // Verify active filter tag shows up
    expect(find.text('Status: Online'), findsOneWidget);

    // Verify list is filtered
    expect(find.text('Temp Tracker A'), findsOneWidget);
    expect(find.text('Ble Sensor B'), findsNothing);
  });
}
