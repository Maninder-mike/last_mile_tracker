import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';

final scorecardServiceProvider = Provider<ScorecardService>((ref) {
  return ScorecardService(ref);
});

final driverScorecardProvider = FutureProvider<DriverScorecard>((ref) {
  return ref.watch(scorecardServiceProvider).calculateScorecard();
});

class ScorecardService {
  final Ref _ref;

  ScorecardService(this._ref);

  Future<DriverScorecard> calculateScorecard() async {
    // 1. Fetch recent readings (simulate last 24h or a specific shift)
    // Normally, we would query `appDatabaseProvider` for a specific time range.
    // For now, we'll use the recentReadingsProvider stream to estimate.
    final latestReadings = await _ref.read(recentReadingsProvider.future);

    if (latestReadings.isEmpty) {
      return DriverScorecard.empty();
    }

    // Aggregations
    int hardBrakingEvents = 0;
    int speedingEvents = 0;
    double maxSpeed = 0;
    int idleTimeMinutes = 0; // Simplified estimation
    int totalTimeActive = 0;

    for (int i = 0; i < latestReadings.length; i++) {
      final reading = latestReadings[i];

      // Speeding
      if (reading.speed > 80.0) {
        // e.g., 80km/h limit
        speedingEvents++;
      }
      if (reading.speed > maxSpeed) {
        maxSpeed = reading.speed;
      }

      // Shock / Hard Braking (using shockValue as a proxy for sudden g-force changes)
      // Let's say a shock value > 300 while moving implies hard braking or impacts.
      if (reading.shockValue > 300.0 && (reading.speed) > 10.0) {
        hardBrakingEvents++;
      }

      // Idle Time (speed == 0 but device is active/in trip)
      if (reading.speed == 0.0 && reading.tripState == 1) {
        idleTimeMinutes +=
            1; // Assuming reading frequency is roughly 1 min for this simulation
      }

      if (reading.tripState == 1) {
        totalTimeActive += 1;
      }
    }

    // Calculate a synthetic score (0-100)
    // - Base 100
    // - Deduct 5 for each hard brake
    // - Deduct 2 for each speeding tick
    double baseScore = 100.0;
    baseScore -= (hardBrakingEvents * 5);
    baseScore -= (speedingEvents * 2);

    // On-Time Delivery Rate (Simulated metric based on trips or shipments)
    // In a real app, this joins with the Trips/Shipments table.
    double onTimeRate = 94.5;

    // Battery Efficiency -> how much drop per hour active
    // Simulated based on current level vs start of shift
    double efficiency = latestReadings.first.batteryLevel;

    return DriverScorecard(
      overallScore: baseScore.clamp(0.0, 100.0),
      hardBrakingEvents: hardBrakingEvents,
      speedingEvents: speedingEvents,
      onTimeDeliveryRate: onTimeRate,
      idleTimeMinutes: idleTimeMinutes,
      totalActiveMinutes: totalTimeActive,
      batteryEfficiency: efficiency,
    );
  }
}

class DriverScorecard {
  final double overallScore;
  final int hardBrakingEvents;
  final int speedingEvents;
  final double onTimeDeliveryRate; // percentage
  final int idleTimeMinutes;
  final int totalActiveMinutes;
  final double batteryEfficiency;

  DriverScorecard({
    required this.overallScore,
    required this.hardBrakingEvents,
    required this.speedingEvents,
    required this.onTimeDeliveryRate,
    required this.idleTimeMinutes,
    required this.totalActiveMinutes,
    required this.batteryEfficiency,
  });

  factory DriverScorecard.empty() {
    return DriverScorecard(
      overallScore: 100.0,
      hardBrakingEvents: 0,
      speedingEvents: 0,
      onTimeDeliveryRate: 100.0,
      idleTimeMinutes: 0,
      totalActiveMinutes: 0,
      batteryEfficiency: 100.0,
    );
  }
}
