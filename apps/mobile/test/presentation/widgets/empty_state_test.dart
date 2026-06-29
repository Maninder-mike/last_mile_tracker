import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:last_mile_tracker/presentation/widgets/empty_state.dart';

void main() {
  group('EmptyState Widget Tests', () {
    testWidgets('renders icon, title, and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: EmptyState(
              icon: CupertinoIcons.info,
              title: 'Empty Title',
              subtitle: 'Empty Subtitle',
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.info), findsOneWidget);
      expect(find.text('Empty Title'), findsOneWidget);
      expect(find.text('Empty Subtitle'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: EmptyState(
              icon: CupertinoIcons.info,
              title: 'Empty Title',
              subtitle: 'Empty Subtitle',
              action: CupertinoButton(
                onPressed: () {},
                child: const Text('Try Again'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
