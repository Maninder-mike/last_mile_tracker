import 'dart:async';
import 'ble_connection_manager.dart';
import 'package:lmt_models/lmt_models.dart';
import 'package:last_mile_tracker/core/constants/ble_constants.dart';

class BleSimulationService {
  final Function(SensorReading) onReadingGenerated;

  Timer? _simulationTimer;
  bool _isSimulating = false;
  bool get isSimulating => _isSimulating;

  BleSimulationService({required this.onReadingGenerated});

  void start() {
    if (_isSimulating) return;
    _isSimulating = true;

    _simulationTimer = Timer.periodic(BleConstants.simulationInterval, (timer) {
      final random = DateTime.now().millisecondsSinceEpoch;
      final speed =
          BleConstants.simSpeedMin +
          (random % BleConstants.simSpeedRange) / 10.0;
      final temp =
          BleConstants.simTempMin + (random % BleConstants.simTempRange) / 10.0;
      final shock = (random % 5);

      final reading = SensorReading(
        timestamp: DateTime.now(),
        lat: BleConstants.simBaseLat + (random % 1000) / 100000.0,
        lon: BleConstants.simBaseLon + (random % 1000) / 100000.0,
        speed: speed,
        temp: temp,
        shockValue: shock,
        batteryLevel:
            BleConstants.simBatteryMin +
            (random % BleConstants.simBatteryRange) / 100.0,
        internalTemp:
            BleConstants.simInternalTempMin +
            (random % BleConstants.simInternalTempRange) / 10.0,
        tripState: 1, // Moving
        rssi: -50 - (random % 40), // -50 to -90
        resetReason: 0,
        uptime: timer.tick,
        isSynced: false,
      );

      onReadingGenerated(reading);
    });
  }

  void stop() {
    _isSimulating = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  // WiFi Simulation
  final _wifiScanController =
      StreamController<List<WifiScanResult>>.broadcast();
  Stream<List<WifiScanResult>> get wifiScanResults =>
      _wifiScanController.stream;

  final _isWifiScanningController = StreamController<bool>.broadcast();
  Stream<bool> get isWifiScanning => _isWifiScanningController.stream;

  Future<void> scanForWifi() async {
    _isWifiScanningController.add(true);
    // Simulate scan delay
    await Future.delayed(const Duration(seconds: 2));

    final results = [
      WifiScanResult("Simulated WiFi 1", -65),
      WifiScanResult("Simulated WiFi 2", -72),
      WifiScanResult("Simulated WiFi 3", -80),
    ];

    _wifiScanController.add(results);
    _isWifiScanningController.add(false);
  }

  void dispose() {
    stop();
    _wifiScanController.close();
    _isWifiScanningController.close();
  }
}
