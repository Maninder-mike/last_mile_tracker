import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show VerticalDivider, Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/core/constants/app_constants.dart';
import 'package:flutter/services.dart';

import 'dashboard/dashboard_page.dart';
import 'map/map_page.dart';
import 'logs/logs_page.dart';
import 'settings/settings_page.dart';

import 'home/widgets/mobile_bottom_nav.dart';
import 'home/widgets/tablet_sidebar.dart';
import 'home/widgets/connection_overlay.dart';

import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:last_mile_tracker/presentation/providers/service_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 1; // Default to Dashboard (index 1)
  bool _checkedForUpdate = false;

  @override
  void initState() {
    super.initState();
    // Auto-check for firmware updates on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_checkedForUpdate) {
        _checkedForUpdate = true;
        ref.read(otaServiceProvider).checkForUpdate(isAutoCheck: true);
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

  final List<HomeMenuItem> _menuItems = const [
    HomeMenuItem(
      icon: CupertinoIcons.map,
      activeIcon: CupertinoIcons.map_fill,
      label: 'Map',
    ),
    HomeMenuItem(
      icon: CupertinoIcons.speedometer,
      activeIcon: CupertinoIcons.speedometer,
      label: 'Dashboard',
    ),
    HomeMenuItem(
      icon: CupertinoIcons.list_bullet,
      activeIcon: CupertinoIcons.list_bullet,
      label: 'Logs',
    ),
    HomeMenuItem(
      icon: CupertinoIcons.settings,
      activeIcon: CupertinoIcons.settings_solid,
      label: 'Settings',
    ),
  ];

  final List<Widget> _pageWidgets = const [
    MapPage(),
    DashboardPage(),
    LogsPage(),
    SettingsPage(),
  ];

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

    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= AppConstants.tabletBreakpoint;

    if (isTablet) {
      return CupertinoPageScaffold(
        child: Row(
          children: [
            TabletSidebar(
              currentIndex: _currentIndex,
              items: _menuItems,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: CupertinoColors.systemGrey5,
            ),
            Expanded(
              child: CupertinoPageScaffold(child: _pageWidgets[_currentIndex]),
            ),
          ],
        ),
      );
    }

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pageWidgets),
          MobileBottomNav(
            currentIndex: _currentIndex,
            items: _menuItems,
            onTap: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            },
          ),
        ],
      ),
    );
  }
}
