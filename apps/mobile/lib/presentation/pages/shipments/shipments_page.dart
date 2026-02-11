import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/shipment_detail_page.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/add_shipment_page.dart';

import 'package:flutter/material.dart' show Colors; // For transparent scaffold
import 'package:last_mile_tracker/domain/models/shipment.dart'; // Import model
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/presentation/providers/tracker_providers.dart';
import 'package:collection/collection.dart';

class ShipmentsPage extends ConsumerStatefulWidget {
  const ShipmentsPage({super.key});

  @override
  ConsumerState<ShipmentsPage> createState() => _ShipmentsPageState();
}

class _ShipmentsPageState extends ConsumerState<ShipmentsPage> {
  final TextEditingController _searchController = TextEditingController();
  // We no longer keep local state for filtered list, we derive it in build
  String _searchQuery = '';

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackersAsync = ref.watch(allTrackersProvider);
    final trackers = trackersAsync.asData?.value ?? [];

    // Merge Mock Data with Live Trackers
    final mergedShipments = Shipment.mockData.map((s) {
      final tracker = trackers.firstWhereOrNull(
        (t) => s.deviceIds.contains(t.id),
      );
      if (tracker != null) {
        return s.copyWith(
          temperature: (tracker.temp ?? 0) != 0
              ? (tracker.temp ?? 0)
              : s.temperature,
          // batteryLevel: tracker.batteryLevel != 0 ? tracker.batteryLevel.toInt() : s.batteryLevel, // Tracker DB has 0 default
          batteryLevel: (tracker.batteryLevel ?? 0).toInt(),
          shockValue: tracker.shockValue ?? 0,
          latitude: (tracker.lat ?? 0) != 0 ? (tracker.lat ?? 0) : s.latitude,
          longitude: (tracker.lon ?? 0) != 0 ? (tracker.lon ?? 0) : s.longitude,
          lastUpdate: tracker.lastSeen,
        );
      }
      return s;
    }).toList();

    // Filter
    final filteredShipments = mergedShipments.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.trackingNumber.toLowerCase().contains(q) ||
          s.origin.toLowerCase().contains(q) ||
          s.destination.toLowerCase().contains(q);
    }).toList();

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent, // Let MainLayout background show
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 68,
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
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

              // Shipment List
              SliverPadding(
                padding: const EdgeInsets.only(
                  bottom: 100,
                ), // Space for fab/navbar
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final shipment = filteredShipments[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: _ShipmentListItem(shipment: shipment),
                    );
                  }, childCount: filteredShipments.length),
                ),
              ),
            ],
          ),
          FloatingHeader(
            title: 'Shipments',
            trailing: CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const AddShipmentPage(),
                  ),
                );
              },
              child: const Icon(
                CupertinoIcons.add,
                size: 20,
                color: CupertinoColors.activeBlue,
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
    final statusColor = _getStatusColor(shipment.status);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ShipmentDetailPage(shipment: shipment),
          ),
        );
      },
      child: GlassContainer(
        opacity: 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shipment.trackingNumber,
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      statusColor,
                      context,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoDynamicColor.resolve(
                        statusColor,
                        context,
                      ).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    shipment.status.name.toUpperCase(),
                    style: TextStyle(
                      color: CupertinoDynamicColor.resolve(
                        statusColor,
                        context,
                      ),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  CupertinoIcons.circle,
                  size: 12,
                  color: CupertinoDynamicColor.resolve(
                    AppTheme.textSecondary,
                    context,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  shipment.origin,
                  style: TextStyle(
                    color: CupertinoDynamicColor.resolve(
                      AppTheme.textSecondary,
                      context,
                    ),
                    fontSize: 13,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(CupertinoIcons.arrow_right, size: 12),
                ),
                Icon(
                  CupertinoIcons.location_solid,
                  size: 12,
                  color: CupertinoDynamicColor.resolve(
                    AppTheme.textSecondary,
                    context,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  shipment.destination,
                  style: TextStyle(
                    color: CupertinoDynamicColor.resolve(
                      AppTheme.textSecondary,
                      context,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TelemetryBadge(
                  icon: CupertinoIcons.thermometer,
                  label: '${shipment.temperature}°C',
                  color: (shipment.temperature ?? 0) > 8
                      ? AppTheme.critical
                      : AppTheme.success,
                ),
                _TelemetryBadge(
                  icon: CupertinoIcons.battery_25,
                  label: '${shipment.batteryLevel}%',
                  color: (shipment.batteryLevel ?? 0) < 20
                      ? AppTheme.warning
                      : AppTheme.success,
                ),
                Text(
                  'ETA: ${_formatDate(shipment.eta)}',
                  style: TextStyle(
                    color: CupertinoDynamicColor.resolve(
                      AppTheme.textSecondary,
                      context,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.inTransit:
        return AppTheme.primary;
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

class _TelemetryBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TelemetryBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: CupertinoDynamicColor.resolve(color, context),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: CupertinoDynamicColor.resolve(color, context),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
