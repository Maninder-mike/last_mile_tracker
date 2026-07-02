/// Converts raw telemetry values into human-readable labels
/// for non-technical users (drivers, warehouse managers).
class TelemetryDisplay {
  TelemetryDisplay._();

  // ── Signal Strength ──────────────────────────────────────────────────

  static String signalLabel(int? rssi) {
    if (rssi == null) return 'No Signal';
    if (rssi > -50) return 'Excellent';
    if (rssi > -60) return 'Strong';
    if (rssi > -70) return 'Good';
    if (rssi > -80) return 'Fair';
    return 'Weak';
  }

  /// Returns a 0–4 bar count for visual signal indicators.
  static int signalBars(int? rssi) {
    if (rssi == null) return 0;
    if (rssi > -50) return 4;
    if (rssi > -60) return 3;
    if (rssi > -70) return 2;
    if (rssi > -80) return 1;
    return 0;
  }

  // ── Impact / Shock ───────────────────────────────────────────────────

  static String impactLabel(int? shockValue) {
    if (shockValue == null || shockValue == 0) return 'None';
    if (shockValue < 2) return 'Low';
    if (shockValue < 5) return 'Medium';
    return 'High';
  }

  static String impactDescription(int? shockValue) {
    if (shockValue == null || shockValue == 0) return 'No impact detected';
    if (shockValue < 2) return 'Minor vibration';
    if (shockValue < 5) return 'Moderate handling';
    return 'Rough handling detected';
  }

  // ── Battery Health (voltage drop) ────────────────────────────────────

  static String healthLabel(double? batteryDropMv) {
    if (batteryDropMv == null) return '--';
    final dropMv = (batteryDropMv * 1000).abs();
    if (dropMv < 100) return 'Healthy';
    if (dropMv < 200) return 'Good';
    return 'Degraded';
  }

  static String healthDescription(double? batteryDropMv) {
    if (batteryDropMv == null) return 'No data available';
    final dropMv = (batteryDropMv * 1000).abs();
    if (dropMv < 100) return 'Battery is performing well';
    if (dropMv < 200) return 'Battery is aging normally';
    return 'Battery may need replacement soon';
  }

  // ── Reset Reason ─────────────────────────────────────────────────────

  static String resetReasonLabel(int? code) {
    if (code == null) return 'Unknown';
    switch (code) {
      case 0:
        return 'Normal';
      case 1:
        return 'Powered on';
      case 2:
        return 'Manual reset';
      case 3:
        return 'Software update';
      case 4:
        return 'Auto-recovery';
      case 5:
        return 'Woke from sleep';
      case 6:
        return 'Low power restart';
      default:
        return 'Restart #$code';
    }
  }

  // ── Uptime ───────────────────────────────────────────────────────────

  static String uptimeLabel(int? uptimeSeconds) {
    if (uptimeSeconds == null || uptimeSeconds == 0) return '--';
    if (uptimeSeconds < 60) return '${uptimeSeconds}s';
    if (uptimeSeconds < 3600) return '${uptimeSeconds ~/ 60}m';
    final hours = uptimeSeconds ~/ 3600;
    final mins = (uptimeSeconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }

  // ── Trip State ───────────────────────────────────────────────────────

  static String tripStateLabel(int? tripState) {
    if (tripState == null) return 'Unknown';
    return tripState == 1 ? 'In Transit' : 'Parked';
  }

  // ── BLE Connection Errors ────────────────────────────────────────────

  static String friendlyBleError(String rawError) {
    final lower = rawError.toLowerCase();

    // GATT errors (Android)
    if (lower.contains('gatt') && lower.contains('133')) {
      return 'Connection failed. Please move closer to the tracker and try again.';
    }
    if (lower.contains('gatt') && lower.contains('8')) {
      return 'Connection timed out. Make sure the tracker is powered on and nearby.';
    }
    if (lower.contains('gatt')) {
      return 'Bluetooth connection error. Try turning Bluetooth off and on, then retry.';
    }

    // Timeout errors
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Could not find the tracker. Make sure it\'s powered on and within range.';
    }

    // Permission errors
    if (lower.contains('permission') || lower.contains('denied')) {
      return 'Bluetooth permission required. Please allow Bluetooth access in your phone settings.';
    }

    // Already connected
    if (lower.contains('already connected')) {
      return 'Already connected to this tracker.';
    }

    // Disconnected during operation
    if (lower.contains('disconnect')) {
      return 'Lost connection to the tracker. It may have moved out of range.';
    }

    // iOS-specific
    if (lower.contains('cbmanager') || lower.contains('powered off')) {
      return 'Bluetooth is turned off. Please enable Bluetooth in your phone settings.';
    }

    // Generic fallback — still avoid raw exception text
    return 'Connection failed. Please make sure the tracker is on and try again.';
  }

  // ── Telemetry Card Help Text ─────────────────────────────────────────

  static const Map<String, String> cardHelpText = {
    'battery': 'Shows how much charge is left in the tracker\'s battery.',
    'temperature': 'The temperature reading from the tracker\'s sensor. '
        'Useful for monitoring cold chain or heat-sensitive shipments.',
    'impact': 'Measures physical impact or vibration on the package. '
        'High values may indicate rough handling during transit.',
    'signal': 'How strong the Bluetooth connection is between your phone '
        'and the tracker. Stay within 10 meters for best results.',
    'health': 'Indicates overall battery condition. A "Degraded" reading '
        'means the battery may need replacement soon.',
    'location': 'The last known GPS position of the tracker. '
        'Updates every few seconds when connected.',
  };
}
