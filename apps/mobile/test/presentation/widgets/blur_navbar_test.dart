import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:last_mile_tracker/presentation/widgets/blur_navbar.dart';

void main() {
  group('BlurNavbar Widget Tests', () {
    testWidgets('renders correct number of items', (WidgetTester tester) async {
      int? tappedIndex;

      final items = [
        const BlurNavbarItem(
          icon: CupertinoIcons.home,
          activeIcon: CupertinoIcons.home,
          label: 'Home',
        ),
        const BlurNavbarItem(
          icon: CupertinoIcons.map,
          activeIcon: CupertinoIcons.map_fill,
          label: 'Map',
        ),
        const BlurNavbarItem(
          icon: CupertinoIcons.settings,
          activeIcon: CupertinoIcons.settings_solid,
          label: 'Settings',
        ),
      ];

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: BlurNavbar(
                currentIndex: 0,
                onTap: (index) {
                  tappedIndex = index;
                },
                items: items,
              ),
            ),
          ),
        ),
      );

      // Verify all items are rendered
      expect(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(GestureDetector),
        ),
        findsNWidgets(3),
      );
      expect(
        find.text('Home'),
        findsOneWidget,
      ); // Only selected has label visible in current design
      expect(find.text('Map'), findsNothing);

      // Tap on the second item
      await tester.tap(find.byIcon(CupertinoIcons.map));
      await tester.pump();

      expect(tappedIndex, equals(1));
    });

    testWidgets('shows badge when badgeCount > 0', (WidgetTester tester) async {
      final items = [
        const BlurNavbarItem(
          icon: CupertinoIcons.home,
          activeIcon: CupertinoIcons.home,
          label: 'Home',
        ),
        const BlurNavbarItem(
          icon: CupertinoIcons.bell,
          activeIcon: CupertinoIcons.bell_fill,
          label: 'Notifications',
          badgeCount: 5,
        ),
      ];

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: BlurNavbar(currentIndex: 0, onTap: (_) {}, items: items),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 9+ badge when badgeCount > 9', (
      WidgetTester tester,
    ) async {
      final items = [
        const BlurNavbarItem(
          icon: CupertinoIcons.home,
          activeIcon: CupertinoIcons.home,
          label: 'Home',
        ),
        const BlurNavbarItem(
          icon: CupertinoIcons.bell,
          activeIcon: CupertinoIcons.bell_fill,
          label: 'Notifications',
          badgeCount: 15,
        ),
      ];

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: BlurNavbar(currentIndex: 0, onTap: (_) {}, items: items),
          ),
        ),
      );

      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('throws assertion error when items > 5', (
      WidgetTester tester,
    ) async {
      final items = List.generate(
        6,
        (index) => const BlurNavbarItem(
          icon: CupertinoIcons.home,
          activeIcon: CupertinoIcons.home,
          label: 'Tab',
        ),
      );

      expect(
        () => BlurNavbar(currentIndex: 0, onTap: (_) {}, items: items),
        throwsAssertionError,
      );
    });
  });
}
