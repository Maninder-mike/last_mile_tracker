import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final activeLoadServiceProvider = Provider((ref) => ActiveLoadService());

class ActiveLoadService {
  static const String _key = 'active_load_device_ids';
  final Set<String> _deviceIds = {};

  ActiveLoadService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    _deviceIds.addAll(list);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _deviceIds.toList());
  }

  Set<String> get activeDeviceIds => Set.unmodifiable(_deviceIds);

  bool isInActiveLoad(String deviceId) => _deviceIds.contains(deviceId);

  Future<void> addToActiveLoad(String deviceId) async {
    _deviceIds.add(deviceId);
    await _save();
  }

  Future<void> removeFromActiveLoad(String deviceId) async {
    _deviceIds.remove(deviceId);
    await _save();
  }

  Future<void> clearActiveLoad() async {
    _deviceIds.clear();
    await _save();
  }

  /// Checks if all trackers in the active load are nearby
  bool isSelectionComplete(List<String> nearbyDeviceIds) {
    if (_deviceIds.isEmpty) return false;
    return _deviceIds.every((id) => nearbyDeviceIds.contains(id));
  }
}

final activeLoadIdsProvider =
    NotifierProvider<ActiveLoadIdsNotifier, Set<String>>(() {
      return ActiveLoadIdsNotifier();
    });

class ActiveLoadIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final service = ref.watch(activeLoadServiceProvider);
    return service.activeDeviceIds;
  }

  // Add methods to mutate if needed, but for now it just reflects the service
}
