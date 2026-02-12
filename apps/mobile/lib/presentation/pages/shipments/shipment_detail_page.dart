import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:fl_chart/fl_chart.dart';

class ShipmentDetailPage extends StatefulWidget {
  final Shipment shipment;

  const ShipmentDetailPage({super.key, required this.shipment});

  @override
  State<ShipmentDetailPage> createState() => _ShipmentDetailPageState();
}

class _ShipmentDetailPageState extends State<ShipmentDetailPage>
    with TickerProviderStateMixin {
  late final _animatedMapController = AnimatedMapController(vsync: this);
  bool _isMapFull = false;

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    if (widget.shipment.latitude != null && widget.shipment.longitude != null) {
      _animatedMapController.animateTo(
        dest: LatLng(widget.shipment.latitude!, widget.shipment.longitude!),
        zoom: 14.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
        AppTheme.background,
        context,
      ),
      child: Stack(
        children: [
          // Background Map Section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child:
                widget.shipment.latitude != null &&
                    widget.shipment.longitude != null
                ? FlutterMap(
                    mapController: _animatedMapController.mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        widget.shipment.latitude!,
                        widget.shipment.longitude!,
                      ),
                      initialZoom: 13.0,
                      onTap: (tapPosition, point) =>
                          setState(() => _isMapFull = false),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              widget.shipment.latitude!,
                              widget.shipment.longitude!,
                            ),
                            width: 120,
                            height: 120,
                            child: _PulseMarker(color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ],
                  )
                : Container(
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
                            'Location unavailable',
                            style: AppTheme.body.copyWith(
                              color: AppTheme.textSecondary,
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
              minChildSize: 0.55,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Hero(
                  tag: 'shipment_card_${widget.shipment.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoDynamicColor.resolve(
                        AppTheme.background,
                        context,
                      ).withValues(alpha: 0.8),
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
                        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: CustomScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
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
                                    color: CupertinoColors.systemGrey3
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn().slideY(begin: -1),

                            // Header
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate(
                                  [
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
                                                  widget
                                                      .shipment
                                                      .trackingNumber,
                                                  style: AppTheme.heading2,
                                                ),
                                              ],
                                            ),
                                            _StatusBadge(
                                              status: widget.shipment.status,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        _RouteInfo(shipment: widget.shipment),
                                        const SizedBox(height: 32),
                                      ]
                                      .animate(interval: 50.ms)
                                      .fadeIn()
                                      .slideX(begin: 0.1),
                                ),
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
                                      title: 'Temp',
                                      value:
                                          '${widget.shipment.temperature ?? "--"}°C',
                                      icon: CupertinoIcons.thermometer,
                                      color:
                                          (widget.shipment.temperature ?? 0) > 8
                                          ? AppTheme.critical
                                          : AppTheme.success,
                                      trend: widget.shipment.temperatureTrend,
                                    ),
                                    ...widget.shipment.additionalTemps.entries
                                        .map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                            ),
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
                                      value:
                                          '${widget.shipment.batteryLevel ?? "--"}%',
                                      icon: CupertinoIcons.battery_25,
                                      color:
                                          (widget.shipment.batteryLevel ?? 0) <
                                              20
                                          ? AppTheme.warning
                                          : AppTheme.success,
                                    ),
                                    if (widget.shipment.batteryDrop !=
                                        null) ...[
                                      const SizedBox(width: 12),
                                      _TelemetryCard(
                                        title: 'Drop',
                                        value:
                                            '${widget.shipment.batteryDrop!.toStringAsFixed(0)}mV',
                                        icon: CupertinoIcons.heart_fill,
                                        color:
                                            widget.shipment.batteryDrop! > 200
                                            ? AppTheme.critical
                                            : (widget.shipment.batteryDrop! >
                                                      100
                                                  ? AppTheme.warning
                                                  : AppTheme.success),
                                      ),
                                    ],
                                    const SizedBox(width: 12),
                                    _TelemetryCard(
                                      title: 'Shock',
                                      value:
                                          '${widget.shipment.shockValue ?? 0}mg',
                                      icon: CupertinoIcons.waveform_circle,
                                      color:
                                          (widget.shipment.shockValue ?? 0) >
                                              500
                                          ? AppTheme.critical
                                          : AppTheme.success,
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().slideX(begin: 0.1),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 32),
                            ),

                            // Timeline
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate(
                                  [
                                        Text(
                                          'Journey Timeline',
                                          style: AppTheme.heading2.copyWith(
                                            fontSize: 18,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const _TimelineItem(
                                          title: 'In Transit',
                                          subtitle: 'Departed distribution hub',
                                          time: '2h ago',
                                          isActive: true,
                                        ),
                                        const _TimelineItem(
                                          title: 'Processed',
                                          subtitle:
                                              'Sorted at sorting facility',
                                          time: '5h ago',
                                        ),
                                        const _TimelineItem(
                                          title: 'Order Tracking Started',
                                          subtitle:
                                              'Shipment record initialized',
                                          time: 'Yesterday',
                                          isLast: true,
                                        ),
                                      ]
                                      .animate(interval: 50.ms)
                                      .fadeIn()
                                      .slideY(begin: 0.1),
                                ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 120),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const FloatingHeader(title: 'Shipment Detail', showBackButton: true),

          // Map Control Actions
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 70,
            child: Column(
              children: [
                _MapActionButton(
                  icon: CupertinoIcons.location_fill,
                  onPressed: _recenterMap,
                ),
                const SizedBox(height: 12),
                _MapActionButton(
                  icon: _isMapFull
                      ? CupertinoIcons.fullscreen_exit
                      : CupertinoIcons.fullscreen,
                  onPressed: () => setState(() => _isMapFull = !_isMapFull),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.5),
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.8,
      padding: EdgeInsets.zero,
      child: CupertinoButton(
        padding: const EdgeInsets.all(12),
        onPressed: onPressed,
        child: Icon(icon, size: 22, color: AppTheme.primary),
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
  final double? trend;

  const _TelemetryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = CupertinoDynamicColor.resolve(color, context);

    return GlassContainer(
      color: effectiveColor.withValues(alpha: 0.05),
      child: Container(
        width: 110,
        height: 140,
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Background Sparkline
            Positioned(
              bottom: 0,
              left: 4,
              right: 4,
              height: 40,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 6,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3),
                        const FlSpot(1, 4),
                        const FlSpot(2, 3.5),
                        const FlSpot(3, 5),
                        const FlSpot(4, 4.5),
                        const FlSpot(5, 5.5),
                        const FlSpot(6, 5),
                      ],
                      isCurved: true,
                      color: effectiveColor.withValues(alpha: 0.3),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: effectiveColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
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
                  const Spacer(),
                  Text(
                    value,
                    style: AppTheme.heading1.copyWith(
                      color: effectiveColor,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTheme.caption.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trend != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          trend! >= 0
                              ? CupertinoIcons.arrow_up_right
                              : CupertinoIcons.arrow_down_right,
                          size: 10,
                          color: effectiveColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
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
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
        // Show detail popup or logs
      },
      child: Row(
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
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                Text(subtitle, style: AppTheme.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: AppTheme.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _PulseMarker extends StatefulWidget {
  final Color color;
  const _PulseMarker({required this.color});

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80 * _controller.value,
              height: 80 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 1 - _controller.value),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
