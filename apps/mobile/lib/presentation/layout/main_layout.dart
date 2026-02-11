import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/blur_navbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';

class MainLayout extends ConsumerStatefulWidget {
  final List<Widget> pages;
  final List<BlurNavbarItem> navItems;

  const MainLayout({super.key, required this.pages, required this.navItems});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Ensure AlertManager is active
    ref.watch(alertManagerProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
        AppTheme.background,
        context,
      ),
      child: Stack(
        children: [
          // Main Content
          IndexedStack(index: _currentIndex, children: widget.pages),

          // Floating Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BlurNavbar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: widget.navItems,
            ),
          ),
        ],
      ),
    );
  }
}
