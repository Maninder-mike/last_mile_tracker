import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';

class ShipmentDetailPage extends ConsumerStatefulWidget {
  final Shipment shipment;

  const ShipmentDetailPage({super.key, required this.shipment});

  @override
  ConsumerState<ShipmentDetailPage> createState() => _ShipmentDetailPageState();
}

class _ShipmentDetailPageState extends ConsumerState<ShipmentDetailPage> {
  final _mapController = MapController();
  bool _isMapFull = false;
  double _replayProgress = 1.0; // 0.0 to 1.0
  bool _isPlaying = false;

  @override
  void dispose() {
    // MapController likely doesn't need dispose in this version, check if it does.
    // Usually it doesn't. Leaving it out for now.
    super.dispose();
  }

  void _recenterMap() {
    if (widget.shipment.latitude != null && widget.shipment.longitude != null) {
      _mapController.move(
        LatLng(widget.shipment.latitude!, widget.shipment.longitude!),
        14.5,
      );
    }
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying && _replayProgress >= 1.0) {
        _replayProgress = 0.0;
      }
    });
    if (_isPlaying) {
      _animateReplay();
    }
  }

  void _animateReplay() async {
    while (_isPlaying && _replayProgress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        _replayProgress += 0.01;
        if (_replayProgress >= 1.0) {
          _replayProgress = 1.0;
          _isPlaying = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentPathAsync = ref.watch(recentPathProvider);
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
                    mapController: _mapController,
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
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.last_mile_tracker.app',
                      ),
                      recentPathAsync.maybeWhen(
                        data: (points) {
                          if (points.isEmpty) return const SizedBox.shrink();

                          // Convert points to LatLng
                          final route = points
                              .map((p) => LatLng(p.lat, p.lon))
                              .toList();
                          // Reverse so oldest is first
                          final reversedRoute = route.reversed.toList();

                          // Calculate current position based on replay progress
                          final progressIndex =
                              (reversedRoute.length - 1) * _replayProgress;
                          final index1 = progressIndex.floor();
                          final index2 = progressIndex.ceil();
                          final fraction = progressIndex - index1;

                          LatLng currentPos;
                          if (index1 == index2) {
                            currentPos = reversedRoute[index1];
                          } else {
                            final p1 = reversedRoute[index1];
                            final p2 = reversedRoute[index2];
                            currentPos = LatLng(
                              p1.latitude +
                                  (p2.latitude - p1.latitude) * fraction,
                              p1.longitude +
                                  (p2.longitude - p1.longitude) * fraction,
                            );
                          }

                          // Only show path up to the current progress
                          final visibleRoute = reversedRoute.sublist(
                            0,
                            index2 + 1,
                          );

                          return Stack(
                            children: [
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: reversedRoute, // Full subtle path
                                    color: CupertinoColors.systemGrey
                                        .withValues(alpha: 0.3),
                                    strokeWidth: 4,
                                  ),
                                  Polyline(
                                    points: visibleRoute, // Active path
                                    color: CupertinoDynamicColor.resolve(
                                      AppTheme.primary,
                                      context,
                                    ),
                                    strokeWidth: 5,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: currentPos,
                                    width: 120,
                                    height: 120,
                                    child: _PulseMarker(
                                      color: CupertinoTheme.of(
                                        context,
                                      ).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        orElse: () => MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                widget.shipment.latitude!,
                                widget.shipment.longitude!,
                              ),
                              width: 120,
                              height: 120,
                              child: _PulseMarker(
                                color: CupertinoTheme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
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

          // Map Masking Gradient
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x00000000),
                    AppTheme.background.withValues(alpha: 0.8),
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
                      border: Border.all(
                        color: CupertinoColors.systemGrey4.withValues(
                          alpha: 0.2,
                        ),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x1A000000),
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
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Shipment ID',
                                                    style: AppTheme.caption
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: 0.5,
                                                        ),
                                                  ),
                                                  Text(
                                                    widget
                                                        .shipment
                                                        .trackingNumber,
                                                    style: AppTheme.heading1
                                                        .copyWith(
                                                          fontSize: 28,
                                                          letterSpacing: -1,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _StatusBadge(
                                              status: widget.shipment.status,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 32),
                                        _JourneyBridge(
                                          shipment: widget.shipment,
                                        ),
                                        const SizedBox(height: 40),
                                      ]
                                      .animate(interval: 50.ms)
                                      .fadeIn()
                                      .slideX(begin: 0.1),
                                ),
                              ),
                            ),

                            // Interactive Timeline Scrubber (Tier 2 Polish)
                            recentPathAsync.maybeWhen(
                              data: (points) {
                                if (points.length < 2) {
                                  return const SliverToBoxAdapter(
                                    child: SizedBox.shrink(),
                                  );
                                }
                                return SliverToBoxAdapter(
                                  child:
                                      Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 16,
                                            ),
                                            child: _RouteScrubber(
                                              progress: _replayProgress,
                                              isPlaying: _isPlaying,
                                              onChanged: (val) {
                                                setState(() {
                                                  _replayProgress = val;
                                                  _isPlaying =
                                                      false; // Pause when scrubbing
                                                });
                                              },
                                              onTogglePlay: _togglePlay,
                                            ),
                                          )
                                          .animate()
                                          .fadeIn(delay: 200.ms)
                                          .slideY(begin: 0.2),
                                );
                              },
                              orElse: () => const SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
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

                            // Quick Action Hub
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _ActionHub(shipment: widget.shipment),
                              ),
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
        child: Icon(
          icon,
          size: 22,
          color: CupertinoTheme.of(context).primaryColor,
        ),
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
        color = CupertinoTheme.of(context).primaryColor;
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

    return Semantics(
      label: 'Shipment Status: ${status.name}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            color,
            context,
          ).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoDynamicColor.resolve(
              color,
              context,
            ).withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(color, context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status.name.toUpperCase(),
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(color, context),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyBridge extends StatelessWidget {
  final Shipment shipment;

  const _JourneyBridge({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return Semantics(
      label: 'Journey from ${shipment.origin} to ${shipment.destination}',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            _buildLocationItem(
              context,
              'Origin',
              shipment.origin,
              CupertinoIcons.circle_fill,
              CupertinoColors.systemGrey,
              showLine: true,
            ),
            _buildLocationItem(
              context,
              'Destination',
              shipment.destination,
              CupertinoIcons.location_solid,
              primaryColor,
              isDestination: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(
    BuildContext context,
    String label,
    String address,
    IconData icon,
    Color color, {
    bool showLine = false,
    bool isDestination = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, CupertinoTheme.of(context).primaryColor],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: AppTheme.body.copyWith(
                  fontWeight: isDestination ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        if (isDestination)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ETA 14:30',
              style: AppTheme.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
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

    return Container(
      width: 120,
      height: 150,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Sparkline
            Positioned(
              bottom: 0,
              left: 4,
              right: 4,
              height: 50,
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
                      color: effectiveColor.withValues(alpha: 0.4),
                      barWidth: 3,
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: effectiveColor),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: AppTheme.heading1.copyWith(
                      color: effectiveColor,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    title,
                    style: AppTheme.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trend != null)
              Positioned(
                top: 16,
                right: 16,
                child: Icon(
                  trend! >= 0
                      ? CupertinoIcons.arrow_up_right
                      : CupertinoIcons.arrow_down_right,
                  size: 14,
                  color: effectiveColor.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionHub extends StatelessWidget {
  final Shipment shipment;

  const _ActionHub({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                context,
                'Call',
                CupertinoIcons.phone_fill,
                CupertinoColors.activeGreen,
                () => HapticFeedback.mediumImpact(),
              ),
              _buildActionButton(
                context,
                'Share',
                CupertinoIcons.share,
                CupertinoColors.activeBlue,
                () => HapticFeedback.mediumImpact(),
              ),
              _buildActionButton(
                context,
                'Report',
                CupertinoIcons.exclamationmark_triangle_fill,
                CupertinoColors.systemRed,
                () => HapticFeedback.mediumImpact(),
              ),
              _buildActionButton(
                context,
                'Logs',
                CupertinoIcons.doc_text_fill,
                CupertinoColors.systemGrey,
                () => HapticFeedback.mediumImpact(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTheme.caption.copyWith()),
      ],
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
                      ? CupertinoTheme.of(context).primaryColor
                      : CupertinoColors.systemGrey4,
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(
                          color: CupertinoDynamicColor.resolve(
                            CupertinoTheme.of(context).primaryColor,
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
                color: CupertinoColors.white,
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

class _RouteScrubber extends StatelessWidget {
  final double progress;
  final bool isPlaying;
  final ValueChanged<double> onChanged;
  final VoidCallback onTogglePlay;

  const _RouteScrubber({
    required this.progress,
    required this.isPlaying,
    required this.onChanged,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Route Replay',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onTogglePlay,
                child: Icon(
                  isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoSlider(
                  value: progress,
                  onChanged: onChanged,
                  activeColor: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
