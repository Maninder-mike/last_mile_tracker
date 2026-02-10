import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ota_providers.g.dart';

@riverpod
class AutoCheckUpdates extends _$AutoCheckUpdates {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

enum OtaStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  installing,
  success,
  error,
}

@riverpod
class FirmwareUpdateStatus extends _$FirmwareUpdateStatus {
  @override
  OtaStatus build() => OtaStatus.upToDate;

  Future<void> checkForUpdates() async {
    state = OtaStatus.checking;
    await Future.delayed(const Duration(seconds: 2));
    // Simulate finding an update if we want to show the flow,
    // but default to up-to-date for now.
    state = OtaStatus.upToDate;
  }

  Future<void> performUpdate() async {
    state = OtaStatus.downloading;
    for (var i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    state = OtaStatus.installing;
    await Future.delayed(const Duration(seconds: 3));
    state = OtaStatus.success;
    await Future.delayed(const Duration(seconds: 2));
    state = OtaStatus.upToDate;
  }
}
