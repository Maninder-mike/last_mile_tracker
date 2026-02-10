class BleConstants {
  static const String deviceName = "Last-Mile-";

  // Environmental Sensing Service
  static const String serviceUuid = "181A";

  // Characteristics
  static const String tempCharUuid = "2A6E";
  static const String locationCharUuid =
      "2A67"; // We re-purpose this for packed data

  // OTA Characteristics
  static const String otaControlUuid = "00000001-0000-1000-8000-00805F9B34FB";
  static const String otaDataUuid = "00000002-0000-1000-8000-00805F9B34FB";

  // Current firmware version (should match ESP32 firmware)
  static const int currentFirmwareVersion = 1;

  // GitHub Releases API
  static const String githubOwner = "Maninder-mike";
  static const String githubRepo = "last_mile_tracker";
}
