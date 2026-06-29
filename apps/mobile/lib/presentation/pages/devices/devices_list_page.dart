import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/presentation/widgets/app_layout.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/presentation/widgets/swipe_action_cell.dart';
import 'package:last_mile_tracker/presentation/widgets/skeleton_loader.dart';
import 'package:last_mile_tracker/presentation/widgets/entrance_animation.dart';
import 'package:last_mile_tracker/presentation/providers/optimistic_favorites_provider.dart';
import 'package:last_mile_tracker/presentation/widgets/empty_state.dart';
import 'device_detail_page.dart';

class DevicesListPage extends ConsumerStatefulWidget {
  const DevicesListPage({super.key});

  @override
  ConsumerState<DevicesListPage> createState() => _DevicesListPageState();
}

class _DevicesListPageState extends ConsumerState<DevicesListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedBattery = 'All';

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showFilterSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      barrierColor: CupertinoColors.black.withValues(alpha: 0.4),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return GlassContainer(
              borderRadius: 20,
              padding: EdgeInsets.zero,
              child: Container(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context).barBackgroundColor.withValues(alpha: 0.8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Devices',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CupertinoDynamicColor.resolve(
                              AppTheme.textPrimary,
                              context,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setModalState(() {
                              _selectedStatus = 'All';
                              _selectedBattery = 'All';
                            });
                            setState(() {
                              _selectedStatus = 'All';
                              _selectedBattery = 'All';
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: CupertinoTheme.of(context).primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status Section
                    Text(
                      'Device Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CupertinoDynamicColor.resolve(
                          AppTheme.textSecondary,
                          context,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterPill(
                          label: 'All Statuses',
                          isSelected: _selectedStatus == 'All',
                          setModalState: setModalState,
                          onTap: () {
                            setState(() => _selectedStatus = 'All');
                          },
                        ),
                        _buildFilterPill(
                          label: 'Online',
                          isSelected: _selectedStatus == 'Online',
                          setModalState: setModalState,
                          onTap: () {
                            setState(() => _selectedStatus = 'Online');
                          },
                        ),
                        _buildFilterPill(
                          label: 'Offline',
                          isSelected: _selectedStatus == 'Offline',
                          setModalState: setModalState,
                          onTap: () {
                            setState(() => _selectedStatus = 'Offline');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Battery Section
                    Text(
                      'Battery Level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CupertinoDynamicColor.resolve(
                          AppTheme.textSecondary,
                          context,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterPill(
                          label: 'All Levels',
                          isSelected: _selectedBattery == 'All',
                          setModalState: setModalState,
                          onTap: () {
                            setState(() => _selectedBattery = 'All');
                          },
                        ),
                        _buildFilterPill(
                          label: 'Low Battery',
                          isSelected: _selectedBattery == 'Low',
                          setModalState: setModalState,
                          onTap: () {
                            setState(() => _selectedBattery = 'Low');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.glow,
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required StateSetter setModalState,
    required VoidCallback onTap,
  }) {
    final activeColor = CupertinoTheme.of(context).primaryColor;
    final textThemeColor = CupertinoDynamicColor.resolve(
      AppTheme.textPrimary,
      context,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setModalState(() {
          onTap();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : CupertinoColors.systemGrey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? activeColor
                : CupertinoColors.systemGrey.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? activeColor : textThemeColor,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final bool hasActiveFilters = _selectedStatus != 'All' || _selectedBattery != 'All';
    final activeColor = CupertinoTheme.of(context).primaryColor;

    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 10,
      width: 36,
      height: 36,
      color: hasActiveFilters ? activeColor.withValues(alpha: 0.15) : null,
      border: Border.all(
        color: hasActiveFilters
            ? activeColor.withValues(alpha: 0.4)
            : CupertinoColors.systemGrey.withValues(alpha: 0.2),
        width: 1,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 20,
              color: hasActiveFilters
                  ? activeColor
                  : CupertinoDynamicColor.resolve(
                      AppTheme.textPrimary,
                      context,
                    ),
            ),
            if (hasActiveFilters)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CupertinoDynamicColor.resolve(
                        AppTheme.surfaceGlass,
                        context,
                      ),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    final activeColor = CupertinoTheme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.24),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: activeColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(
              CupertinoIcons.xmark,
              size: 10,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannedDevicesAsync = ref.watch(allTrackersProvider);
    final connectionState =
        ref.watch(bleConnectionStateProvider).value ??
        BluetoothConnectionState.disconnected;
    final connectedDevice = ref.watch(bleServiceProvider).connectedDevice;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
        AppTheme.background,
        context,
      ),
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(allTrackersProvider);
                  await Future.delayed(const Duration(milliseconds: 800));
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 68,
                ),
              ),

              // Search & Filter Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPadding.searchBar,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoSearchTextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: TextStyle(
                            color: CupertinoDynamicColor.resolve(
                              AppTheme.textPrimary,
                              context,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showFilterSheet,
                        child: _buildFilterButton(),
                      ),
                    ],
                  ),
                ),
              ),

              // Active Filters tags (compact chips)
              if (_selectedStatus != 'All' || _selectedBattery != 'All')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedStatus != 'All')
                            _buildActiveFilterChip(
                              label: 'Status: $_selectedStatus',
                              onDeleted: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedStatus = 'All');
                              },
                            ),
                          if (_selectedStatus != 'All' && _selectedBattery != 'All')
                            const SizedBox(width: 8),
                          if (_selectedBattery != 'All')
                            _buildActiveFilterChip(
                              label: 'Battery: Low',
                              onDeleted: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedBattery = 'All');
                              },
                            ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedStatus = 'All';
                                _selectedBattery = 'All';
                              });
                            },
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoTheme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SliverPadding(
                padding: AppPadding.horizontal,
                sliver: scannedDevicesAsync.when(
                  data: (devices) {
                    // Apply filtering
                    final filteredDevices = devices.where((tracker) {
                      final q = _searchQuery.toLowerCase();
                      final matchesSearch =
                          tracker.name.toLowerCase().contains(q) ||
                          tracker.id.toLowerCase().contains(q);

                      final isOnline =
                          tracker.status.toLowerCase() == 'online' ||
                          (connectedDevice?.remoteId.str == tracker.id &&
                              connectionState ==
                                  BluetoothConnectionState.connected);

                      final matchesStatus =
                          _selectedStatus == 'All' ||
                          (_selectedStatus == 'Online' && isOnline) ||
                          (_selectedStatus == 'Offline' && !isOnline);

                      final matchesBattery =
                          _selectedBattery == 'All' ||
                          (_selectedBattery == 'Low' &&
                              (tracker.batteryLevel ?? 100) < 20);

                      return matchesSearch && matchesStatus && matchesBattery;
                    }).toList();

                    if (filteredDevices.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: CupertinoIcons.search,
                          title: 'No Devices Found',
                          subtitle:
                              'Try adjusting your filters or search query to find what you\'re looking for.',
                        ),
                      );
                    }
                    return SliverPrototypeExtentList(
                      prototypeItem: Padding(
                        padding: AppPadding.listItem,
                        child: _DeviceCard(
                          id: 'proto',
                          name: 'Prototype',
                          status: 'active',
                          battery: 100,
                          lastSeen: 'Now',
                          isCritical: false,
                          isFavorite: false,
                          type: 'Tracker',
                        ),
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tracker = filteredDevices[index];
                        final isConnected =
                            connectedDevice?.remoteId.str == tracker.id &&
                            connectionState ==
                                BluetoothConnectionState.connected;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.s12),
                          child: SwipeActionCell(
                            groupTag: tracker.id,
                            startActions: [
                              createSwipeAction(
                                icon: tracker.isFavorite
                                    ? CupertinoIcons.star_fill
                                    : CupertinoIcons.star,
                                label: 'Favorite',
                                color: AppTheme.primary,
                                onPressed: () {
                                  ref
                                      .read(
                                        optimisticFavoritesProvider.notifier,
                                      )
                                      .toggleFavorite(
                                        tracker.id,
                                        tracker.isFavorite,
                                      );
                                },
                              ),
                            ],
                            endActions: [
                              createSwipeAction(
                                icon: CupertinoIcons
                                    .antenna_radiowaves_left_right,
                                label: 'Ping',
                                color: AppTheme.primary,
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  debugPrint('Ping: ${tracker.id}');
                                },
                              ),
                              createSwipeAction(
                                icon: isConnected
                                    ? CupertinoIcons.stop_circle
                                    : CupertinoIcons.link,
                                label: isConnected ? 'Disconnect' : 'Connect',
                                color: isConnected
                                    ? AppTheme.critical
                                    : AppTheme.success,
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  if (isConnected) {
                                    ref.read(bleServiceProvider).disconnect();
                                  } else {
                                    ref
                                        .read(bleServiceProvider)
                                        .connectToTracker(tracker.id);
                                  }
                                },
                              ),
                            ],
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => DeviceDetailPage(
                                      deviceId: tracker.id,
                                      name: tracker.name.isEmpty
                                          ? 'Unknown Device'
                                          : tracker.name,
                                    ),
                                  ),
                                );
                              },
                              child: EntranceAnimation(
                                index: index,
                                child: Hero(
                                  tag: 'device_card_${tracker.id}',
                                  child: _DeviceCard(
                                    id: tracker.id,
                                    name: tracker.name.isEmpty
                                        ? 'Unknown Device'
                                        : tracker.name,
                                    status: isConnected
                                        ? 'Connected'
                                        : tracker.status,
                                    battery: (tracker.batteryLevel ?? 0)
                                        .toInt(),
                                    lastSeen: _formatLastSeen(tracker.lastSeen),
                                    isCritical:
                                        (tracker.batteryLevel ?? 0) < 20 ||
                                        (tracker.shockValue ?? 0) > 0,
                                    isFavorite: ref.watch(
                                      isFavoriteProvider(tracker.id),
                                    ),
                                    type: 'Tracker',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: filteredDevices.length),
                    );
                  },
                  loading: () => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: AppPadding.listItem,
                        child: SkeletonLoader.deviceCard(),
                      ),
                      childCount: 5,
                    ),
                  ),
                  error: (err, stack) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: AppPadding.all,
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: AppTheme.critical),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingHeader(
              title: 'Devices',
              showBackButton: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _DeviceCard extends StatelessWidget {
  final String id;
  final String name;
  final String status;
  final int battery;
  final String lastSeen;
  final bool isCritical;
  final bool isFavorite;
  final String type;

  const _DeviceCard({
    required this.id,
    required this.name,
    required this.status,
    required this.battery,
    required this.lastSeen,
    this.isCritical = false,
    this.isFavorite = false,
    this.type = 'Tracker',
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Row(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(AppTheme.s8),
            shape: BoxShape.circle,
            color: CupertinoTheme.of(context).primaryColor,
            opacity: 0.1,
            child: Icon(
              type == 'Gateway' ? CupertinoIcons.wifi : CupertinoIcons.location,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ),
          AppGaps.horizontalLarge,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: AppTheme.heading2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFavorite) ...[
                            AppGaps.horizontalSmall,
                            const Icon(
                              CupertinoIcons.star_fill,
                              size: 14,
                              color: CupertinoColors.systemYellow,
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StatusBadge(status: status, isCritical: isCritical),
                  ],
                ),
                AppGaps.small,
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        id,
                        style: AppTheme.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppGaps.horizontalMedium,
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppGaps.horizontalMedium,
                    Text(lastSeen, style: AppTheme.caption),
                  ],
                ),
                AppGaps.small,
              ],
            ),
          ),
          AppGaps.horizontalStandard,
          Container(
            width: AppTheme.iconSizeMedium,
            height: AppTheme.iconSizeMedium,
            alignment: Alignment.center,
            child: Icon(
              battery > 20
                  ? CupertinoIcons.battery_100
                  : CupertinoIcons.battery_25,
              size: AppTheme.iconSizeSmall,
              color: battery > 20 ? AppTheme.success : AppTheme.critical,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isCritical;

  const _StatusBadge({required this.status, required this.isCritical});

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppTheme.critical : AppTheme.success;
    final effectiveColor = CupertinoDynamicColor.resolve(color, context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.s8,
        vertical: AppTheme.s4,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: effectiveColor,
          fontSize: AppTheme.label.fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
