import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/shipment_detail_page.dart';
import 'package:flutter/material.dart' show Colors; // For transparent scaffold
import 'package:last_mile_tracker/domain/models/shipment.dart'; // Import model
import 'package:last_mile_tracker/presentation/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

class ShipmentsPage extends StatefulWidget {
  const ShipmentsPage({super.key});

  @override
  State<ShipmentsPage> createState() => _ShipmentsPageState();
}

class _ShipmentsPageState extends State<ShipmentsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Shipment> _filteredShipments = Shipment.mockData;

  void _onSearchChanged(String query) {
    setState(() {
      _filteredShipments = Shipment.mockData.where((s) {
        final q = query.toLowerCase();
        return s.trackingNumber.toLowerCase().contains(q) ||
            s.origin.toLowerCase().contains(q) ||
            s.destination.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent, // Let MainLayout background show
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Shipments'),
            backgroundColor: Colors.transparent,
            border: null,
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add, size: 28),
              onPressed: () {
                // TODO: Navigate to Add Shipment
              },
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
            padding: const EdgeInsets.only(bottom: 100), // Space for fab/navbar
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final shipment = _filteredShipments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _ShipmentListItem(shipment: shipment),
                );
              }, childCount: _filteredShipments.length),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
