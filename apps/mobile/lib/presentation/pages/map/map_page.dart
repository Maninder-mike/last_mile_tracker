import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:last_mile_tracker/presentation/providers/providers.dart';
import '../../widgets/floating_header.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingAsync = ref.watch(latestReadingProvider);
    final pathAsync = ref.watch(recentPathProvider);
    // final width = MediaQuery.of(context).size.width;
    // final isTablet = width >= AppConstants.tabletBreakpoint;

    // Default location (SF)
    const defaultCenter = LatLng(37.7749, -122.4194);

    final readingData = readingAsync.asData?.value;
    final pathData = pathAsync.asData?.value;

    final center = readingData != null
        ? LatLng(readingData.lat, readingData.lon)
        : defaultCenter;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Full Screen Map
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 15.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.last_mile_tracker',
              ),
              if (pathData != null && pathData.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pathData
                          .map((e) => LatLng(e.lat, e.lon))
                          .toList(),
                      color: CupertinoColors.systemBlue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              if (readingData != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(readingData.lat, readingData.lon),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        CupertinoIcons.location_solid,
                        color: CupertinoColors.systemRed,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Floating Header
          const FloatingHeader(title: 'Live Map'),
        ],
      ),
    );
  }
}
