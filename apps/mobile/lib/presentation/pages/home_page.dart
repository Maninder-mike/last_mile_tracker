import 'package:last_mile_tracker/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/services.dart';

// import 'dashboard/dashboard_page.dart'; // Removed
import 'map/map_page.dart';
import 'settings/settings_page.dart';
import 'fleet/fleet_overview_page.dart'; // New
import 'shipments/shipments_page.dart';

import 'package:last_mile_tracker/presentation/layout/main_layout.dart'; // New
import 'package:last_mile_tracker/presentation/widgets/blur_navbar.dart'; // New
import 'home/widgets/connection_overlay.dart';

import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/service_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // int _currentIndex = 1; // Handled by MainLayout now
  bool _checkedForUpdate = false;

  @override
  void initState() {
    super.initState();
    // Auto-check for firmware updates on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Initialize sync manager to start background syncing
      ref.read(syncManagerProvider);

      if (!_checkedForUpdate) {
        _checkedForUpdate = true;
        final deviceVersion = ref
            .read(bleServiceProvider)
            .deviceFirmwareVersion;
        ref
            .read(otaServiceProvider)
            .checkForUpdate(
              isAutoCheck: true,
              deviceFirmwareVersion: deviceVersion,
            );
      }
    });

    // Enter full-screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0x00000000),
        systemNavigationBarColor: Color(0x00000000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for connection state changes to show notifications
    ref.listen<AsyncValue<BluetoothConnectionState>>(
      bleConnectionStateProvider,
      (previous, next) {
        next.whenData((state) {
          if (previous?.value != state) {
            ConnectionOverlay.show(context, state);
          }
        });
      },
    );

    // Prepare pages for the new MainLayout
    // Index 0: Fleet Overview (New)
    // Index 1: Map (Old)
    // Index 2: Devices (Connect/Disconnect - Old Dashboard/Logs mixed)
    // Index 3: Settings (Old)
    final l10n = AppLocalizations.of(context)!;

    final pages = [
      const FleetOverviewPage(),
      const MapPage(),
      const ShipmentsPage(),
      const SettingsPage(),
    ];

    final navItems = [
      BlurNavbarItem(
        icon: CupertinoIcons.home,
        activeIcon: CupertinoIcons.home,
        label: l10n.homeTab,
      ),
      const BlurNavbarItem(
        icon: CupertinoIcons.map,
        activeIcon: CupertinoIcons.map_fill,
        label: 'Map',
      ),
      BlurNavbarItem(
        icon: CupertinoIcons.cube_box,
        activeIcon: CupertinoIcons.cube_box_fill,
        label: l10n.shipmentsTab,
      ),
      BlurNavbarItem(
        icon: CupertinoIcons.settings,
        activeIcon: CupertinoIcons.settings_solid,
        label: l10n.settingsTab,
      ),
    ];

    return MainLayout(pages: pages, navItems: navItems);
  }
}
