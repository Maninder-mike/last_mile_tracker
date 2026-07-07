import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/blur_navbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';

import 'package:last_mile_tracker/logic/proximity_service.dart';
import 'package:last_mile_tracker/logic/alert_manager.dart';
import 'package:last_mile_tracker/logic/fleet_inventory_service.dart';
import 'package:last_mile_tracker/domain/services/connectivity_service.dart';

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
    // Ensure Background Services are active
    ref.watch(alertManagerProvider);
    ref.watch(proximityServiceProvider);
    ref.watch(fleetInventoryServiceProvider);

    final isOnline = ref.watch(connectivityStatusProvider).value ?? true;

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: CupertinoColors.transparent,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: CupertinoColors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoDynamicColor.resolve(
          AppTheme.background,
          context,
        ),
        child: Stack(
          children: [
            // Main Content
            IndexedStack(index: _currentIndex, children: widget.pages),

            if (!isOnline)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: const _OfflineBanner(),
              ),

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
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Offline status banner',
      hint: 'Indicates the app is currently running in offline mode. Local changes will sync when connection is restored.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemRed.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.wifi_exclamationmark,
            color: CupertinoColors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Offline Mode - Changes will sync later',
            style: AppTheme.caption.copyWith(
              color: CupertinoColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
     ),
    );
  }
}
