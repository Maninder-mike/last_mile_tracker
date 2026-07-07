import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/l10n/app_localizations.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/shipments_page.dart';
import 'package:last_mile_tracker/presentation/providers/shipment_match_provider.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';

void main() {
  final mockShipments = [
    Shipment(
      id: 'shipment-1',
      trackingNumber: 'LMT-1001',
      status: ShipmentStatus.inTransit,
      origin: 'New York',
      destination: 'Los Angeles',
      eta: DateTime.now().add(const Duration(days: 1)),
      deviceIds: ['device-1'],
    ),
    Shipment(
      id: 'shipment-2',
      trackingNumber: 'LMT-1002',
      status: ShipmentStatus.delivered,
      origin: 'Chicago',
      destination: 'Miami',
      eta: DateTime.now().subtract(const Duration(days: 1)),
      deviceIds: [],
    ),
  ];

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        mergedShipmentsProvider.overrideWithValue(
          AsyncValue.data(mockShipments),
        ),
      ],
      child: const CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShipmentsPage(),
      ),
    );
  }

  testWidgets('ShipmentsPage renders search field and filter button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify search field exists
    expect(find.byType(CupertinoSearchTextField), findsOneWidget);

    // Verify filter icon button exists
    expect(find.byIcon(CupertinoIcons.slider_horizontal_3), findsOneWidget);

    // Verify shipments render in the list
    expect(find.text('LMT-1001'), findsOneWidget);
    expect(find.text('LMT-1002'), findsOneWidget);

    // Clear pending stream and overlay timers
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'Tapping filter button opens filter bottom sheet and applies status filter',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the filter button to open sheet
      final filterButton = find.byIcon(CupertinoIcons.slider_horizontal_3);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Verify bottom sheet titles
      expect(find.text('Filter Shipments'), findsOneWidget);

      // Select Status "Delivered" pill in the wrap
      await tester.tap(find.text('Delivered'));
      await tester.pump();

      // Tap Apply Filters
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Bottom sheet should be closed
      expect(find.text('Filter Shipments'), findsNothing);

      // Verify active filter tag shows up
      expect(find.text('Status: Delivered'), findsOneWidget);

      // Verify list is filtered (only LMT-1002 is shown, LMT-1001 is hidden)
      expect(find.text('LMT-1002'), findsOneWidget);
      expect(find.text('LMT-1001'), findsNothing);

      // Tap the 'x' button on the filter tag to clear it
      await tester.tap(find.byIcon(CupertinoIcons.xmark));
      await tester.pumpAndSettle();

      // Verify tag is gone and list is restored
      expect(find.text('Status: Delivered'), findsNothing);
      expect(find.text('LMT-1001'), findsOneWidget);
      expect(find.text('LMT-1002'), findsOneWidget);

      // Clear pending stream and overlay timers
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
