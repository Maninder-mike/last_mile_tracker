import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/presentation/widgets/filter_chip_bar.dart';
import 'package:last_mile_tracker/presentation/widgets/app_layout.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:last_mile_tracker/presentation/providers/ble_providers.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:last_mile_tracker/presentation/widgets/swipe_action_cell.dart';
import 'package:last_mile_tracker/presentation/widgets/skeleton_loader.dart';
import 'package:last_mile_tracker/presentation/widgets/entrance_animation.dart';
import 'package:last_mile_tracker/presentation/providers/optimistic_favorites_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final scannedDevicesAsync = ref.watch(allTrackersProvider);
    final connectionState =
        ref.watch(bleConnectionStateProvider).value ??
        BluetoothConnectionState.disconnected;
    final connectedDevice = ref.watch(bleServiceProvider).connectedDevice;

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(allTrackersProvider);
                  await Future.delayed(const Duration(milliseconds: 800));
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 60,
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPadding.searchBar,
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
              ),

              // Filters
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    FilterChipBar<String>(
                      items: [
                        FilterItem(label: 'All Devices', value: 'All'),
                        FilterItem(label: 'Online', value: 'Online'),
                        FilterItem(label: 'Offline', value: 'Offline'),
                      ],
                      selectedValue: _selectedStatus,
                      onSelected: (value) =>
                          setState(() => _selectedStatus = value),
                    ),
                    AppGaps.standard,
                    FilterChipBar<String>(
                      items: [
                        FilterItem(label: 'All Battery', value: 'All'),
                        FilterItem(label: 'Low Battery', value: 'Low'),
                      ],
                      selectedValue: _selectedBattery,
                      onSelected: (value) =>
                          setState(() => _selectedBattery = value),
                    ),
                    AppGaps.large,
                  ],
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
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 32.0),
                            child: Text(
                              'No devices found',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ),
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
                                      initialName: tracker.name.isEmpty
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
                      (context, index) => SkeletonLoader.deviceCard(),
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
          const FloatingHeader(title: 'Devices'),
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
          Container(
            padding: const EdgeInsets.all(AppTheme.s8),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                AppTheme.primary,
                context,
              ).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == 'Gateway' ? CupertinoIcons.wifi : CupertinoIcons.location,
              color: CupertinoDynamicColor.resolve(AppTheme.primary, context),
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
