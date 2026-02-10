import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show VerticalDivider, Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/core/constants/app_constants.dart';
import 'dashboard/dashboard_page.dart';
import 'map/map_page.dart';
import 'logs/logs_page.dart';
import 'settings/settings_page.dart';
import 'package:flutter/services.dart';
import '../widgets/glass_container.dart';
import '../widgets/connection_status_icon.dart';
import '../providers/providers.dart';

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

  final List<({Widget child, String title, IconData icon})> _pages = [
    (child: const MapPage(), title: 'Map', icon: CupertinoIcons.map),
    (
      child: const DashboardPage(),
      title: 'Dashboard',
      icon: CupertinoIcons.speedometer,
    ),
    (child: const LogsPage(), title: 'Logs', icon: CupertinoIcons.list_bullet),
    (
      child: const SettingsPage(),
      title: 'Settings',
      icon: CupertinoIcons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen for connection state changes to show notifications
    ref.listen<AsyncValue<BluetoothConnectionState>>(
      bleConnectionStateProvider,
      (previous, next) {
        next.whenData((state) {
          if (previous?.value != state) {
            _showConnectionNotification(state);
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
            _buildSidebar(),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: CupertinoColors.systemGrey5,
            ),
            Expanded(
              child: CupertinoPageScaffold(
                // Removed navigationBar for full screen experience
                child: _pages[_currentIndex].child,
              ),
            ),
          ],
        ),
      );
    }

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Content
          IndexedStack(
            index: _currentIndex,
            children: _pages.map((p) => p.child).toList(),
          ),

          // Floating Bottom Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 8,
            child: SafeArea(
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 16,
                ),
                borderRadius: 32,
                opacity: 0.15,
                border: Border.all(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.1)
                      : CupertinoColors.black.withValues(alpha: 0.05),
                  width: 0.5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_pages.length, (index) {
                    final p = _pages[index];
                    final isSelected = _currentIndex == index;
                    return _buildNavItem(index, p.icon, p.title, isSelected);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? theme.primaryColor
                : (isDark
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.systemGrey),
            size: isSelected ? 28 : 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? theme.primaryColor
                  : (isDark
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey),
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectionNotification(BluetoothConnectionState state) {
    final isConnected = state == BluetoothConnectionState.connected;
    final message = isConnected ? 'Tracker Connected' : 'Tracker Disconnected';
    final color = isConnected
        ? CupertinoColors.activeGreen
        : CupertinoColors.systemRed;
    final icon = isConnected
        ? CupertinoIcons.bluetooth
        : CupertinoIcons.bluetooth;

    // Use Overlay to show a temporary toast
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: CupertinoColors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: CupertinoColors.systemGroupedBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Tracker',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final p = _pages[index];
                final isSelected = _currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: isSelected ? CupertinoColors.activeBlue : null,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => setState(() => _currentIndex = index),
                    child: Row(
                      children: [
                        Icon(
                          p.icon,
                          size: 20,
                          color: isSelected
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          p.title,
                          style: TextStyle(
                            color: isSelected
                                ? CupertinoColors.white
                                : CupertinoColors.label,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Spacer(),
                    ConnectionStatusIcon(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
