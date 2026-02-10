import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/presentation/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

class ShipmentDetailPage extends StatelessWidget {
  final Shipment shipment;

  const ShipmentDetailPage({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Background "Map" (Placeholder)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              color: CupertinoColors.systemGrey6,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.map,
                      size: 48,
                      color: CupertinoColors.systemGrey4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Map View Placeholder',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Draggable/Scrollable Sheet Content
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      AppTheme.background,
                      context,
                    ).withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          // Handle Bar
                          SliverToBoxAdapter(
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey3,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),

                          // Header
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tracking Number',
                                          style: AppTheme.caption,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          shipment.trackingNumber,
                                          style: AppTheme.heading2,
                                        ),
                                      ],
                                    ),
                                    _StatusBadge(status: shipment.status),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _RouteInfo(shipment: shipment),
                                const SizedBox(height: 32),
                              ]),
                            ),
                          ),

                          // Telemetry Section
                          SliverToBoxAdapter(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  _TelemetryCard(
                                    title: 'Primary Temp',
                                    value: '${shipment.temperature ?? "--"}°C',
                                    icon: CupertinoIcons.thermometer,
                                    color: (shipment.temperature ?? 0) > 8
                                        ? AppTheme.critical
                                        : AppTheme.success,
                                  ),
                                  ...shipment.additionalTemps.entries.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: _TelemetryCard(
                                        title: e.key,
                                        value: '${e.value}°C',
                                        icon: CupertinoIcons.thermometer,
                                        color: e.value > 8
                                            ? AppTheme.critical
                                            : AppTheme.success,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _TelemetryCard(
                                    title: 'Battery',
                                    value: '${shipment.batteryLevel ?? "--"}%',
                                    icon: CupertinoIcons.battery_25,
                                    color: (shipment.batteryLevel ?? 0) < 20
                                        ? AppTheme.warning
                                        : AppTheme.success,
                                  ),
                                  if (shipment.batteryDrop != null) ...[
                                    const SizedBox(width: 12),
                                    _TelemetryCard(
                                      title: 'Health (Drop)',
                                      value:
                                          '${shipment.batteryDrop!.toStringAsFixed(0)}mV',
                                      icon: CupertinoIcons.heart_fill,
                                      color: shipment.batteryDrop! > 200
                                          ? AppTheme.critical
                                          : (shipment.batteryDrop! > 100
                                                ? AppTheme.warning
                                                : AppTheme.success),
                                    ),
                                  ],
                                  const SizedBox(width: 12),
                                  const _TelemetryCard(
                                    title: 'Shock',
                                    value: '0G',
                                    icon: CupertinoIcons.waveform_circle,
                                    color: AppTheme.success,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 32)),

                          // Timeline
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                Text(
                                  'Timeline',
                                  style: AppTheme.heading2.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _TimelineItem(
                                  title: 'Package in Transit',
                                  subtitle: 'Departed from distribution center',
                                  time: '2 hours ago',
                                  isActive: true,
                                ),
                                _TimelineItem(
                                  title: 'Package Processed',
                                  subtitle: 'Sorted at facility',
                                  time: '5 hours ago',
                                ),
                                _TimelineItem(
                                  title: 'Order Placed',
                                  subtitle: 'Shipment created',
                                  time: 'Yesterday',
                                  isLast: true,
                                ),
                              ]),
                            ),
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: GlassContainer(
              padding: const EdgeInsets.all(8),
              borderRadius: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(CupertinoIcons.back, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ShipmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ShipmentStatus.inTransit:
        color = AppTheme.primary;
        break;
      case ShipmentStatus.delivered:
        color = AppTheme.success;
        break;
      case ShipmentStatus.delayed:
        color = AppTheme.warning;
        break;
      case ShipmentStatus.atRisk:
        color = AppTheme.critical;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          color,
          context,
        ).withValues(alpha: 0.1),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
            color,
            context,
          ).withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(color, context),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RouteInfo extends StatelessWidget {
  final Shipment shipment;

  const _RouteInfo({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Icon(
              CupertinoIcons.circle,
              size: 12,
              color: CupertinoDynamicColor.resolve(
                AppTheme.textSecondary,
                context,
              ),
            ),
            Container(
              height: 30,
              width: 1,
              color: CupertinoDynamicColor.resolve(
                AppTheme.textSecondary,
                context,
              ),
            ),
            Icon(
              CupertinoIcons.location_solid,
              size: 12,
              color: CupertinoDynamicColor.resolve(AppTheme.primary, context),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Origin', style: AppTheme.caption),
            Text(shipment.origin, style: AppTheme.body),
            const SizedBox(height: 16),
            Text('Destination', style: AppTheme.caption),
            Text(shipment.destination, style: AppTheme.body),
          ],
        ),
      ],
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _TelemetryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = CupertinoDynamicColor.resolve(color, context);

    return GlassContainer(
      color: effectiveColor.withValues(alpha: 0.05),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: effectiveColor),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTheme.heading2.copyWith(color: effectiveColor),
            ),
            const SizedBox(height: 4),
            Text(title, style: AppTheme.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isActive;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.time,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive
                    ? CupertinoDynamicColor.resolve(AppTheme.primary, context)
                    : CupertinoColors.systemGrey4,
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(
                        color: CupertinoDynamicColor.resolve(
                          AppTheme.primary,
                          context,
                        ).withValues(alpha: 0.3),
                        width: 4,
                      )
                    : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: CupertinoColors.systemGrey5,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTheme.caption),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Text(time, style: AppTheme.caption),
      ],
    );
  }
}
