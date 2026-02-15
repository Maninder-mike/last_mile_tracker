import 'package:flutter_test/flutter_test.dart';
import 'package:last_mile_tracker/data/services/ble/ble_scanner.dart';

void main() {
  group('BLE Connectivity Dummy Test', () {
    test('BleScanner should initialize with default values', () {
      final scanner = BleScanner();

      expect(scanner.isScanning, isFalse);
    });

    test(
      'BleScanner should have an empty discovered devices list initially',
      () async {
        final scanner = BleScanner();

        final devices = await scanner.discoveredDevices.first;
        expect(devices, isEmpty);
      },
    );
  });
}
