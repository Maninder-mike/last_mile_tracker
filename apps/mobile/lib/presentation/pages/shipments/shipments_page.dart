import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/presentation/providers/optimistic_favorites_provider.dart';
import 'package:last_mile_tracker/presentation/providers/shipment_match_provider.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:last_mile_tracker/presentation/widgets/entrance_animation.dart';
import 'package:last_mile_tracker/presentation/widgets/filter_chip_bar.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/app_layout.dart';
import 'package:last_mile_tracker/presentation/widgets/skeleton_loader.dart';
import 'package:last_mile_tracker/presentation/widgets/swipe_action_cell.dart';
import 'package:last_mile_tracker/presentation/widgets/empty_state.dart';
import 'package:last_mile_tracker/logic/share_service.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/shipment_detail_page.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/add_shipment_page.dart';

class ShipmentsPage extends ConsumerStatefulWidget {
  const ShipmentsPage({super.key});

  @override
  ConsumerState<ShipmentsPage> createState() => _ShipmentsPageState();
}

class _ShipmentsPageState extends ConsumerState<ShipmentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ShipmentStatus? _selectedStatus;
  String _selectedTimeRange = 'All';

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shipmentsAsync = ref.watch(mergedShipmentsProvider);

    // Filter
    // This filtering logic will now be applied inside the `shipmentsAsync.when` block
    // to ensure it operates on the data once it's available.

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent, // Let MainLayout background show
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(allTrackersProvider);
                  ref.invalidate(
                    mergedShipmentsProvider,
                  ); // Invalidate merged shipments too
                  await Future.delayed(const Duration(milliseconds: 800));
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 68,
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPadding.searchBar,
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
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
                    AppGaps.medium,
                    FilterChipBar<ShipmentStatus?>(
                      items: [
                        FilterItem(label: 'All Status', value: null),
                        ...ShipmentStatus.values.map(
                          (s) => FilterItem(
                            label:
                                s.name[0].toUpperCase() + s.name.substring(1),
                            value: s,
                          ),
                        ),
                      ],
                      selectedValue: _selectedStatus,
                      onSelected: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedStatus = value);
                      },
                    ),
                    AppGaps.standard,
                    FilterChipBar<String>(
                      items: [
                        FilterItem(label: 'All Time', value: 'All'),
                        FilterItem(label: 'Today', value: 'Today'),
                        FilterItem(label: 'This Week', value: 'This Week'),
                        FilterItem(label: 'This Month', value: 'This Month'),
                      ],
                      selectedValue: _selectedTimeRange,
                      onSelected: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTimeRange = value);
                      },
                    ),
                    AppGaps.medium,
                  ],
                ),
              ),

              // Shipment List
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: shipmentsAsync.when(
                  data: (shipments) {
                    final filteredShipments = shipments.where((s) {
                      final q = _searchQuery.toLowerCase();
                      final matchesSearch =
                          s.trackingNumber.toLowerCase().contains(q) ||
                          s.origin.toLowerCase().contains(q) ||
                          s.destination.toLowerCase().contains(q);

                      final matchesStatus =
                          _selectedStatus == null ||
                          s.status == _selectedStatus;

                      bool matchesTime = true;
                      final now = DateTime.now();
                      if (_selectedTimeRange == 'Today') {
                        matchesTime =
                            s.eta.year == now.year &&
                            s.eta.month == now.month &&
                            s.eta.day == now.day;
                      } else if (_selectedTimeRange == 'This Week') {
                        matchesTime = s.eta.isAfter(
                          now.subtract(const Duration(days: 7)),
                        );
                      } else if (_selectedTimeRange == 'This Month') {
                        matchesTime = s.eta.isAfter(
                          now.subtract(const Duration(days: 30)),
                        );
                      }

                      return matchesSearch && matchesStatus && matchesTime;
                    }).toList();

                    if (filteredShipments.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: CupertinoIcons.cube_box,
                          title: 'No Shipments Found',
                          subtitle:
                              'Try adjusting your filters or search query to find what you\'re looking for.',
                        ),
                      );
                    }
                    return SliverPrototypeExtentList(
                      prototypeItem: Padding(
                        padding: AppPadding.listItem,
                        child: _ShipmentListItem(
                          shipment: Shipment.mockData.first.copyWith(
                            id: 'prototype',
                          ),
                        ),
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final shipment = filteredShipments[index];
                        return Padding(
                          padding: AppPadding.listItem,
                          child: SwipeActionCell(
                            groupTag: shipment.id,
                            startActions: [
                              createSwipeAction(
                                icon: shipment.isFavorite
                                    ? CupertinoIcons.star_fill
                                    : CupertinoIcons.star,
                                label: 'Favorite',
                                color: CupertinoTheme.of(context).primaryColor,
                                onPressed: () {
                                  if (shipment.deviceIds.isNotEmpty) {
                                    ref
                                        .read(
                                          optimisticFavoritesProvider.notifier,
                                        )
                                        .toggleFavorite(
                                          shipment.deviceIds.first,
                                          shipment.isFavorite,
                                        );
                                    HapticFeedback.mediumImpact();
                                  }
                                },
                              ),
                            ],
                            endActions: [
                              createSwipeAction(
                                icon: CupertinoIcons.share,
                                label: 'Share',
                                color: CupertinoColors.systemGrey,
                                onPressed: () {
                                  ShareService.shareShipment(shipment);
                                },
                              ),
                              createSwipeAction(
                                icon: CupertinoIcons.trash,
                                label: 'Delete',
                                color: AppTheme.critical,
                                onPressed: () {
                                  debugPrint('Delete: ${shipment.id}');
                                },
                              ),
                            ],
                            child: EntranceAnimation(
                              index: index,
                              child: _ShipmentListItem(shipment: shipment),
                            ),
                          ),
                        );
                      }, childCount: filteredShipments.length),
                    );
                  },
                  loading: () => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: AppPadding.horizontal,
                        child: SkeletonLoader.shipmentCard(),
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
          FloatingHeader(
            title: 'Shipments',
            trailing: Semantics(
              label: 'Add shipment',
              button: true,
              child: CupertinoButton(
                minimumSize: Size(AppTheme.iconSizeMedium, AppTheme.iconSizeMedium),
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const AddShipmentPage(),
                    ),
                  );
                },
                child: Icon(
                  CupertinoIcons.add,
                  size: AppTheme.iconSizeMedium,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentListItem extends StatelessWidget {
  final Shipment shipment;

  const _ShipmentListItem({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, shipment.status);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ShipmentDetailPage(shipment: shipment),
          ),
        );
      },
      child: Hero(
        tag: 'shipment_card_${shipment.id}',

        child: GlassContainer(
          opacity: 0.6,
          padding: AppPadding.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      shipment.trackingNumber,
                      style: AppTheme.heading2.copyWith(
                        letterSpacing: -0.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  _StatusBadge(status: shipment.status, color: statusColor),
                ],
              ),
              AppGaps.standard,
              Row(
                children: [
                  _RouteDot(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  AppGaps.horizontalMedium,
                  Expanded(
                    child: Text(
                      '${shipment.origin} → ${shipment.destination}',
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              AppGaps.large,
              Row(
                children: [
                  _TelemetryPill(
                    icon: CupertinoIcons.thermometer,
                    label: '${shipment.temperature}°C',
                    color: (shipment.temperature ?? 0) > 8
                        ? AppTheme.critical
                        : AppTheme.success,
                  ),
                  AppGaps.horizontalMedium,
                  _TelemetryPill(
                    icon: CupertinoIcons.battery_25,
                    label: '${shipment.batteryLevel}%',
                    color: (shipment.batteryLevel ?? 0) < 20
                        ? AppTheme.warning
                        : AppTheme.success,
                  ),
                  const Spacer(),
                  Text(
                    'ETA: ${_formatDate(shipment.eta)}',
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.inTransit:
        return CupertinoTheme.of(context).primaryColor;
      case ShipmentStatus.delivered:
        return AppTheme.success;
      case ShipmentStatus.delayed:
        return AppTheme.warning;
      case ShipmentStatus.atRisk:
        return AppTheme.critical;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

class _StatusBadge extends StatelessWidget {
  final ShipmentStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          color,
          context,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
            color,
            context,
          ).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(color, context),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  final Color color;
  const _RouteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TelemetryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TelemetryPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = CupertinoDynamicColor.resolve(color, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
