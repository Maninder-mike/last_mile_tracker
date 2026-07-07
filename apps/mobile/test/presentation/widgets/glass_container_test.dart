import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

void main() {
  group('GlassContainer Widget Tests', () {
    testWidgets('renders child content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassContainer(child: Text('Hello Glass')),
          ),
        ),
      );

      expect(find.text('Hello Glass'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (
      WidgetTester tester,
    ) async {
      int tapCount = 0;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassContainer(
              onTap: () {
                tapCount++;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapCount, equals(1));
    });
  });
}
