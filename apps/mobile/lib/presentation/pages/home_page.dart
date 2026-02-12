import 'package:last_mile_tracker/presentation/pages/devices/devices_list_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/services.dart';

// import 'dashboard/dashboard_page.dart'; // Removed
import 'map/map_page.dart';
import 'settings/settings_page.dart';
import 'fleet/fleet_overview_page.dart'; // New
import 'shipments/shipments_page.dart'; // New

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
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
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
    final pages = [
      const FleetOverviewPage(),
      const MapPage(),
      const ShipmentsPage(),
      const DevicesListPage(), // Added Devices Page
      const SettingsPage(),
    ];

    final navItems = [
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
        icon: CupertinoIcons.cube_box,
        activeIcon: CupertinoIcons.cube_box_fill,
        label: 'Shipments',
      ),
      const BlurNavbarItem(
        icon: CupertinoIcons.device_phone_portrait,
        activeIcon: CupertinoIcons.device_phone_portrait,
        label: 'Devices',
      ),
      const BlurNavbarItem(
        icon: CupertinoIcons.settings,
        activeIcon: CupertinoIcons.settings_solid,
        label: 'Settings',
      ),
    ];

    return MainLayout(pages: pages, navItems: navItems);
  }
}
