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
  double _replayProgress = 1.0; // 0.0 to 1.0
  bool _isPlaying = false;
  bool _copied = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _recenterMap() {
    if (widget.shipment.latitude != null && widget.shipment.longitude != null) {
      _mapController.move(
        LatLng(widget.shipment.latitude!, widget.shipment.longitude!),
        13.5,
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

  void _showTelemetryHistory({
    required String title,
    required String currentValue,
    required Color color,
    required String unit,
    required List<double> history,
  }) {
    HapticFeedback.mediumImpact();

    // Calculate average and peak
    final sum = history.fold<double>(0, (prev, element) => prev + element);
    final avg = history.isEmpty ? 0.0 : sum / history.length;
    final peak = history.isEmpty
        ? 0.0
        : history.reduce((curr, next) => curr > next ? curr : next);

    final spots = List.generate(
      history.length,
      (index) => FlSpot(index.toDouble(), history[index]),
    );

    // Determine min/max Y for aesthetics
    double minY = history.isEmpty
        ? 0
        : history.reduce((curr, next) => curr < next ? curr : next) - 1.0;
    double maxY = history.isEmpty ? 10 : peak + 1.0;
    if (minY < 0) minY = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => _TelemetryHistorySheet(
        title: title,
        currentValue: currentValue,
        color: color,
        unit: unit,
        spots: spots,
        minY: minY,
        maxY: maxY,
        avg: avg,
        peak: peak,
      ),
    );
  }

  void _handleCall() {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Contact Logistics Center'),
        message: const Text(
          'Connect with the operational agents for this route.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            child: const Text('Call Dispatch Hub (Operations)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            child: const Text('Call Carrier Dispatch (LastMile Prime)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            child: const Text('Call On-Route Driver'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _handleShare() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(
      ClipboardData(
        text:
            'https://tracker.lastmile.com/shipment/${widget.shipment.trackingNumber}',
      ),
    );
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Tracking Link Shared'),
        content: Text(
          'Secure tracking link for ${widget.shipment.trackingNumber} has been copied to your clipboard.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Done'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _handleReport() {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) =>
          _ReportIssueSheet(trackingNumber: widget.shipment.trackingNumber),
    );
  }

  void _handleLogs() {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _SensorLogsSheet(shipment: widget.shipment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentPathAsync = ref.watch(recentPathProvider);
    final topSpacer = MediaQuery.of(context).padding.top + 70.0;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
        AppTheme.background,
        context,
      ),
      child: Stack(
        children: [
          // Main Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Spacer for Floating Header
              SliverToBoxAdapter(child: SizedBox(height: topSpacer)),

              // Top Info & ID Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CupertinoDynamicColor.resolve(
                        AppTheme.surface,
                        context,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: CupertinoDynamicColor.resolve(
                          CupertinoColors.systemGrey4,
                          context,
                        ).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SHIPMENT ID',
                                    style: AppTheme.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        widget.shipment.trackingNumber,
                                        style: AppTheme.heading2.copyWith(
                                          fontSize: 24,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: widget
                                                  .shipment
                                                  .trackingNumber,
                                            ),
                                          );
                                          HapticFeedback.selectionClick();
                                          setState(() => _copied = true);
                                          Future.delayed(
                                            const Duration(seconds: 1),
                                            () {
                                              if (mounted) {
                                                setState(() => _copied = false);
                                              }
                                            },
                                          );
                                        },
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: _copied
                                              ? Icon(
                                                  CupertinoIcons.checkmark_alt,
                                                  key: const ValueKey(
                                                    'checked',
                                                  ),
                                                  color: AppTheme.success,
                                                  size: 20,
                                                )
                                              : Icon(
                                                  CupertinoIcons.doc_on_doc,
                                                  key: const ValueKey('copy'),
                                                  color: AppTheme.textSecondary,
                                                  size: 16,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(status: widget.shipment.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.cube_box,
                              size: 14,
                              color: CupertinoColors.systemGrey2.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cargo Type: Cold Chain • Carrier: LastMile Prime',
                              style: AppTheme.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Journey Card Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: _JourneyBridge(shipment: widget.shipment),
                ),
              ),

              // Embedded Map Card Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: CupertinoDynamicColor.resolve(
                        AppTheme.surface,
                        context,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: CupertinoDynamicColor.resolve(
                          CupertinoColors.systemGrey4,
                          context,
                        ).withValues(alpha: 0.25),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Positioned.fill(
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
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                        subdomains: const ['a', 'b', 'c', 'd'],
                                        userAgentPackageName:
                                            'com.last_mile_tracker.app',
                                      ),
                                      ...recentPathAsync.maybeWhen(
                                        data: (points) {
                                          if (points.isEmpty) return [];

                                          final route = points
                                              .map((p) => LatLng(p.lat, p.lon))
                                              .toList();
                                          final reversedRoute = route.reversed
                                              .toList();

                                          if (reversedRoute.length < 2) {
                                            return [
                                              MarkerLayer(
                                                markers: [
                                                  Marker(
                                                    point: reversedRoute.first,
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
                                            ];
                                          }

                                          final progressIndex =
                                              (reversedRoute.length - 1) *
                                              _replayProgress;
                                          final index1 = progressIndex.floor();
                                          final index2 = progressIndex.ceil();
                                          final fraction =
                                              progressIndex - index1;

                                          LatLng currentPos;
                                          if (index1 == index2) {
                                            currentPos = reversedRoute[index1];
                                          } else {
                                            final p1 = reversedRoute[index1];
                                            final p2 = reversedRoute[index2];
                                            currentPos = LatLng(
                                              p1.latitude +
                                                  (p2.latitude - p1.latitude) *
                                                      fraction,
                                              p1.longitude +
                                                  (p2.longitude -
                                                          p1.longitude) *
                                                      fraction,
                                            );
                                          }

                                          final visibleRoute = reversedRoute
                                              .sublist(0, index2 + 1);

                                          return [
                                            PolylineLayer(
                                              polylines: [
                                                Polyline(
                                                  points: reversedRoute,
                                                  color: CupertinoColors
                                                      .systemGrey
                                                      .withValues(alpha: 0.3),
                                                  strokeWidth: 4,
                                                ),
                                                Polyline(
                                                  points: visibleRoute,
                                                  color:
                                                      CupertinoDynamicColor.resolve(
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
                                          ];
                                        },
                                        orElse: () => [
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: LatLng(
                                                  widget.shipment.latitude!,
                                                  widget.shipment.longitude!,
                                                ),
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
                                            size: 40,
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
                          // Map Control Overlay (inside Card)
                          if (widget.shipment.latitude != null &&
                              widget.shipment.longitude != null)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Column(
                                children: [
                                  _MapActionButton(
                                    icon: CupertinoIcons.location_fill,
                                    onPressed: _recenterMap,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Replay Scrubber Section (inline under Map Card)
              recentPathAsync.maybeWhen(
                data: (points) {
                  if (points.length < 2) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _RouteScrubber(
                        progress: _replayProgress,
                        isPlaying: _isPlaying,
                        onChanged: (val) {
                          setState(() {
                            _replayProgress = val;
                            _isPlaying = false;
                          });
                        },
                        onTogglePlay: _togglePlay,
                      ),
                    ),
                  );
                },
                orElse: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Telemetry Section
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _TelemetryCard(
                        title: 'Temperature',
                        value: '${widget.shipment.temperature ?? "--"}°C',
                        icon: CupertinoIcons.thermometer,
                        color: (widget.shipment.temperature ?? 0) > 8
                            ? AppTheme.critical
                            : AppTheme.success,
                        trend: widget.shipment.temperatureTrend,
                        history: const [4.0, 4.2, 4.5, 4.3, 4.6, 4.4, 4.5],
                        unit: '°C',
                        onTap: () => _showTelemetryHistory(
                          title: 'Temperature Trend',
                          currentValue:
                              '${widget.shipment.temperature ?? "--"}°C',
                          color: (widget.shipment.temperature ?? 0) > 8
                              ? AppTheme.critical
                              : AppTheme.success,
                          unit: '°C',
                          history: const [4.0, 4.2, 4.5, 4.3, 4.6, 4.4, 4.5],
                        ),
                      ),
                      ...widget.shipment.additionalTemps.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: _TelemetryCard(
                            title: e.key,
                            value: '${e.value}°C',
                            icon: CupertinoIcons.thermometer,
                            color: e.value > 8
                                ? AppTheme.critical
                                : AppTheme.success,
                            history: [
                              e.value - 0.5,
                              e.value - 0.2,
                              e.value,
                              e.value - 0.1,
                              e.value + 0.3,
                              e.value,
                            ],
                            unit: '°C',
                            onTap: () => _showTelemetryHistory(
                              title: '${e.key} Trend',
                              currentValue: '${e.value}°C',
                              color: e.value > 8
                                  ? AppTheme.critical
                                  : AppTheme.success,
                              unit: '°C',
                              history: [
                                e.value - 0.5,
                                e.value - 0.2,
                                e.value,
                                e.value - 0.1,
                                e.value + 0.3,
                                e.value,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _TelemetryCard(
                        title: 'Battery',
                        value: '${widget.shipment.batteryLevel ?? "--"}%',
                        icon: CupertinoIcons.battery_25,
                        color: (widget.shipment.batteryLevel ?? 0) < 20
                            ? AppTheme.warning
                            : AppTheme.success,
                        history: const [90, 89, 88, 86, 86, 85, 85],
                        unit: '%',
                        onTap: () => _showTelemetryHistory(
                          title: 'Battery Level Trend',
                          currentValue:
                              '${widget.shipment.batteryLevel ?? "--"}%',
                          color: (widget.shipment.batteryLevel ?? 0) < 20
                              ? AppTheme.warning
                              : AppTheme.success,
                          unit: '%',
                          history: const [90, 89, 88, 86, 86, 85, 85],
                        ),
                      ),
                      if (widget.shipment.batteryDrop != null) ...[
                        const SizedBox(width: 12),
                        _TelemetryCard(
                          title: 'Drop Rate',
                          value:
                              '${widget.shipment.batteryDrop!.toStringAsFixed(0)}mV',
                          icon: CupertinoIcons.heart_fill,
                          color: widget.shipment.batteryDrop! > 200
                              ? AppTheme.critical
                              : (widget.shipment.batteryDrop! > 100
                                    ? AppTheme.warning
                                    : AppTheme.success),
                          history: const [50, 80, 95, 110, 115, 120],
                          unit: 'mV',
                          onTap: () => _showTelemetryHistory(
                            title: 'Battery Discharge Drop Rate',
                            currentValue:
                                '${widget.shipment.batteryDrop!.toStringAsFixed(0)}mV',
                            color: widget.shipment.batteryDrop! > 200
                                ? AppTheme.critical
                                : (widget.shipment.batteryDrop! > 100
                                      ? AppTheme.warning
                                      : AppTheme.success),
                            unit: 'mV',
                            history: const [50, 80, 95, 110, 115, 120],
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      _TelemetryCard(
                        title: 'Shock Impact',
                        value: '${widget.shipment.shockValue ?? 0}mg',
                        icon: CupertinoIcons.waveform_circle,
                        color: (widget.shipment.shockValue ?? 0) > 500
                            ? AppTheme.critical
                            : AppTheme.success,
                        history: const [10, 12, 10, 11, 125, 15, 10],
                        unit: 'mg',
                        onTap: () => _showTelemetryHistory(
                          title: 'Shock Forces Analysis',
                          currentValue: '${widget.shipment.shockValue ?? 0}mg',
                          color: (widget.shipment.shockValue ?? 0) > 500
                              ? AppTheme.critical
                              : AppTheme.success,
                          unit: 'mg',
                          history: const [10, 12, 10, 11, 125, 15, 10],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Quick Action Hub
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: _ActionHub(
                    onCallPressed: _handleCall,
                    onSharePressed: _handleShare,
                    onReportPressed: _handleReport,
                    onLogsPressed: _handleLogs,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Journey Timeline History
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'JOURNEY TIMELINE',
                      style: AppTheme.label.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _TimelineItem(
                      title: 'In Transit',
                      subtitle: 'Departed distribution sorting hub',
                      time: '2h ago',
                      location: 'South San Francisco Depot',
                      isActive: true,
                    ),
                    const _TimelineItem(
                      title: 'Processed',
                      subtitle: 'Sorted and scanned at sorting facility',
                      time: '5h ago',
                      location: 'Oakland Logistics Center',
                    ),
                    const _TimelineItem(
                      title: 'Order Tracking Started',
                      subtitle:
                          'Shipment record initialized & telemetry active',
                      time: 'Yesterday',
                      location: 'Warehouse Hub 12A',
                      isLast: true,
                    ),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // Pinned Floating Header (matching the app's floating navbar / header UI)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingHeader(
              title: 'Shipment Detail',
              showBackButton: true,
            ),
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

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (!WidgetsBinding.instance.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      _controller.repeat();
    }
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
              width: 14 * _controller.value,
              height: 14 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: 0.6 * (1.0 - _controller.value),
                ),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            color,
            context,
          ).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoDynamicColor.resolve(
              color,
              context,
            ).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingDot(color: CupertinoDynamicColor.resolve(color, context)),
            const SizedBox(width: 6),
            Text(
              status.name.toUpperCase(),
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(color, context),
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double maxExtent = size.height;
    double dashHeight = 4.0;
    double dashSpace = 4.0;
    double currentY = 0.0;

    while (currentY < maxExtent) {
      canvas.drawLine(
        Offset(size.width / 2, currentY),
        Offset(size.width / 2, currentY + dashHeight),
        paint,
      );
      currentY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGrey6,
            context,
          ).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemGrey4,
              context,
            ).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            _buildLocationItem(
              context,
              'ORIGIN PORT',
              shipment.origin,
              CupertinoIcons.circle,
              CupertinoColors.systemGrey,
              timestamp: 'Departed: Jun 23, 10:15 AM',
              showLine: true,
            ),
            const SizedBox(height: 4),
            _buildLocationItem(
              context,
              'DESTINATION PORT',
              shipment.destination,
              CupertinoIcons.location_solid,
              primaryColor,
              timestamp: 'ETA: Jun 24, 02:30 PM',
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
    required String timestamp,
    bool showLine = false,
    bool isDestination = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            if (showLine)
              CustomPaint(
                size: const Size(2, 36),
                painter: _DottedLinePainter(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGrey3,
                    context,
                  ).withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.label.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: AppTheme.body.copyWith(
                  fontWeight: isDestination ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timestamp,
                style: AppTheme.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isDestination)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(
              'ETA 14:30',
              style: AppTheme.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
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
  final List<double> history;
  final String unit;
  final VoidCallback onTap;

  const _TelemetryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    required this.history,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = CupertinoDynamicColor.resolve(color, context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 150,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Sparkline (Smooth curve, Faded Area)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 55,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (history.length - 1).toDouble(),
                    minY: history.isEmpty
                        ? 0
                        : history.reduce((a, b) => a < b ? a : b) - 0.5,
                    maxY: history.isEmpty
                        ? 10
                        : history.reduce((a, b) => a > b ? a : b) + 0.5,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          history.length,
                          (index) => FlSpot(index.toDouble(), history[index]),
                        ),
                        isCurved: true,
                        color: effectiveColor.withValues(alpha: 0.5),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              effectiveColor.withValues(alpha: 0.15),
                              effectiveColor.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: effectiveColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 16, color: effectiveColor),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: effectiveColor,
                            boxShadow: [
                              BoxShadow(
                                color: effectiveColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 1),
                    Text(
                      title,
                      style: AppTheme.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
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
                  right: 28,
                  child: Icon(
                    trend! >= 0
                        ? CupertinoIcons.arrow_up_right
                        : CupertinoIcons.arrow_down_right,
                    size: 13,
                    color: effectiveColor.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionHub extends StatelessWidget {
  final VoidCallback onCallPressed;
  final VoidCallback onSharePressed;
  final VoidCallback onReportPressed;
  final VoidCallback onLogsPressed;

  const _ActionHub({
    required this.onCallPressed,
    required this.onSharePressed,
    required this.onReportPressed,
    required this.onLogsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemGrey6,
          context,
        ).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGrey4,
            context,
          ).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: AppTheme.label.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                context,
                'Call',
                CupertinoIcons.phone_fill,
                CupertinoColors.activeGreen,
                onCallPressed,
              ),
              _buildActionButton(
                context,
                'Share',
                CupertinoIcons.share,
                CupertinoColors.activeBlue,
                onSharePressed,
              ),
              _buildActionButton(
                context,
                'Report',
                CupertinoIcons.exclamationmark_triangle_fill,
                CupertinoColors.systemRed,
                onReportPressed,
              ),
              _buildActionButton(
                context,
                'Logs',
                CupertinoIcons.doc_text_fill,
                CupertinoColors.systemGrey,
                onLogsPressed,
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String location;
  final bool isActive;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.location,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
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
                  height: 48,
                  color: CupertinoColors.systemGrey5,
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isActive
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(subtitle, style: AppTheme.caption.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.placemark,
                      size: 11,
                      color: CupertinoColors.systemGrey3,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: AppTheme.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTheme.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
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
    );
    if (!WidgetsBinding.instance.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      _controller.repeat();
    }
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
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemGrey6,
          context,
        ).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGrey4,
            context,
          ).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ROUTE REPLAY',
                style: AppTheme.label.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.8,
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
          const SizedBox(height: 6),
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
                  size: 26,
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

// Telemetry Historical Trend Sheet Modal
class _TelemetryHistorySheet extends StatelessWidget {
  final String title;
  final String currentValue;
  final Color color;
  final String unit;
  final List<FlSpot> spots;
  final double minY;
  final double maxY;
  final double avg;
  final double peak;

  const _TelemetryHistorySheet({
    required this.title,
    required this.currentValue,
    required this.color,
    required this.unit,
    required this.spots,
    required this.minY,
    required this.maxY,
    required this.avg,
    required this.peak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(AppTheme.surface, context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTheme.heading2.copyWith(fontSize: 20)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: const Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: CupertinoColors.systemGrey2,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current Reading: $currentValue (Normal Status)',
            style: AppTheme.caption.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildStatBox('Average', '${avg.toStringAsFixed(1)}$unit', color),
              const SizedBox(width: 16),
              _buildStatBox(
                'Peak Value',
                '${peak.toStringAsFixed(1)}$unit',
                color,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Main Interactive Line Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: CupertinoColors.systemGrey4.withValues(alpha: 0.25),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final hours = [
                          '10:00',
                          '11:00',
                          '12:00',
                          '13:00',
                          '14:00',
                          '15:00',
                          '16:00',
                        ];
                        if (value.toInt() >= 0 &&
                            value.toInt() < hours.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              hours[value.toInt()],
                              style: const TextStyle(
                                fontSize: 9,
                                color: CupertinoColors.systemGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}$unit',
                          style: const TextStyle(
                            fontSize: 9,
                            color: CupertinoColors.systemGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spots.isEmpty ? 6 : (spots.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: CupertinoColors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.25),
                          color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color themeColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.label.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTheme.heading2.copyWith(
                fontSize: 18,
                color: themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Issue Report Sheet Modal
class _ReportIssueSheet extends StatefulWidget {
  final String trackingNumber;
  const _ReportIssueSheet({required this.trackingNumber});

  @override
  State<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<_ReportIssueSheet> {
  String _selectedIssue = 'Delay';
  final _notesController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(AppTheme.surface, context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.6,
      child: _submitted
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: AppTheme.success,
                  size: 64,
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  'Issue Submitted Successfully',
                  style: AppTheme.heading2.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Operations team has been alerted for ${widget.trackingNumber}.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                CupertinoButton.filled(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Report Route Exception',
                      style: AppTheme.heading2.copyWith(fontSize: 18),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Exception Category',
                  style: AppTheme.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Delay', 'Temp Spike', 'Shock Breach', 'Hardware']
                      .map(
                        (category) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () =>
                                  setState(() => _selectedIssue = category),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedIssue == category
                                      ? CupertinoTheme.of(context).primaryColor
                                      : CupertinoColors.systemGrey6,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedIssue == category
                                          ? CupertinoColors.white
                                          : AppTheme.resolvedTextPrimary(
                                              context,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Add Context Notes',
                  style: AppTheme.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: CupertinoTextField(
                    controller: _notesController,
                    placeholder: 'Describe the exception or damage details...',
                    placeholderStyle: const TextStyle(
                      color: CupertinoColors.systemGrey3,
                      fontSize: 13,
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 6,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      setState(() => _submitted = true);
                    },
                    child: const Text('Submit Report'),
                  ),
                ),
              ],
            ),
    );
  }
}

// Live Sensor Logs Modal
class _SensorLogsSheet extends StatelessWidget {
  final Shipment shipment;
  const _SensorLogsSheet({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(AppTheme.surface, context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sensor telemetry logs',
                style: AppTheme.heading2.copyWith(fontSize: 18),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Raw packet broadcasts for shipment ID: ${shipment.trackingNumber}',
            style: AppTheme.caption,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildLogLine(
                  '14:28:15',
                  'BLE Broadcast Packet Received from device: ${shipment.deviceIds.firstOrNull ?? "dev-01"}',
                  'OK',
                  CupertinoColors.systemGreen,
                ),
                _buildLogLine(
                  '14:20:00',
                  'GPS Location telemetry packet lat: ${shipment.latitude ?? 37.77}, lon: ${shipment.longitude ?? -122.41}',
                  'OK',
                  CupertinoColors.systemGreen,
                ),
                _buildLogLine(
                  '14:15:30',
                  'Temp Probe reads ${shipment.temperature ?? 4.5}°C (Trend: stable)',
                  'OK',
                  CupertinoColors.systemGreen,
                ),
                _buildLogLine(
                  '14:00:10',
                  'Battery level logged at ${shipment.batteryLevel ?? 85}% (Voltage: 3750mV)',
                  'OK',
                  CupertinoColors.systemGreen,
                ),
                _buildLogLine(
                  '13:45:00',
                  'Impact force sensor registered: ${shipment.shockValue ?? 0}mg (normal range)',
                  'OK',
                  CupertinoColors.systemGreen,
                ),
                _buildLogLine(
                  '13:30:15',
                  'Proximity scan performed: 2 neighbor tags detected in cargo hold',
                  'INFO',
                  CupertinoColors.systemBlue,
                ),
                _buildLogLine(
                  '12:15:00',
                  'Shipment route monitoring initialized',
                  'SYSTEM',
                  CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(
    String time,
    String message,
    String tag,
    Color tagColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: tagColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: tagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
