import 'dart:async';
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

  void dispose() {
    stop();
  }
}
