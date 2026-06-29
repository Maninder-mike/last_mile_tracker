import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:last_mile_tracker/presentation/widgets/filter_chip_bar.dart';

void main() {
  group('FilterChipBar Widget Tests', () {
    testWidgets('renders all chips from the list', (WidgetTester tester) async {
      final items = [
        FilterItem(label: 'All', value: 'all'),
        FilterItem(label: 'Active', value: 'active'),
        FilterItem(label: 'Pending', value: 'pending'),
      ];

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: FilterChipBar<String>(
              items: items,
              selectedValue: 'all',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('triggers onSelected callback when a chip is tapped', (WidgetTester tester) async {
      String? selectedValue;
      final items = [
        FilterItem(label: 'All', value: 'all'),
        FilterItem(label: 'Active', value: 'active'),
      ];

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: FilterChipBar<String>(
              items: items,
              selectedValue: 'all',
              onSelected: (value) {
                selectedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Active'));
      await tester.pump();

      expect(selectedValue, equals('active'));
    });
  });
}
