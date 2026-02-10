import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'service_providers.dart';

part 'location_providers.g.dart';

@riverpod
class UserLocation extends _$UserLocation {
  static const _permissionKey = 'location_permission_requested';

  @override
  Future<LatLng?> build() async {
    final storage = ref.watch(secureStorageProvider);
    final hasAsked = await storage.read(key: _permissionKey) == 'true';

    if (!hasAsked) {
      // We don't automatically request on build to avoid annoying the user on startup.
      // The MapPage will call requestPermission() when the user taps the button.
      return null;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return _getCurrentLocation();
    }
    return null;
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  Future<bool> requestPermission() async {
    final storage = ref.read(secureStorageProvider);

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    await storage.write(key: _permissionKey, value: 'true');

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      state = AsyncValue.data(await _getCurrentLocation());
      return true;
    }

    return false;
  }
}
