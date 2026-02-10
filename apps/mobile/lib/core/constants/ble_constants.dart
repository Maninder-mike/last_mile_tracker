class BleConstants {
  static const String deviceName = "Last-Mile-";

  // Environmental Sensing Service
  static const String serviceUuid = "181A";

  // Characteristics
  static const String tempCharUuid = "2A6E";
  static const String extendedTempCharUuid = "2A6F";
  static const String locationCharUuid =
      "2A67"; // We re-purpose this for packed data

  // OTA Characteristics
  static const String otaControlUuid = "00000001-0000-1000-8000-00805F9B34FB";
  static const String otaDataUuid = "00000002-0000-1000-8000-00805F9B34FB";

  // WiFi Provisioning (Custom)
  static const String wifiServiceUuid = "0000FF00-0000-1000-8000-00805F9B34FB";
  static const String wifiConfigUuid = "0000FF01-0000-1000-8000-00805F9B34FB";

  // Current firmware version (should match ESP32 firmware)
  static const int currentFirmwareVersion = 1;

  // GitHub Releases API
  static const String githubOwner = "Maninder-mike";
  static const String githubRepo = "last_mile_tracker";

  // Scan & Connection Settings
  static const Duration scanTimeout = Duration(seconds: 15);
  static const Duration scanStartDelay = Duration(milliseconds: 500);
  static const Duration initialReconnectDelay = Duration(seconds: 1);
  static const Duration maxReconnectDelay = Duration(seconds: 32);

  // Data Settings
  static const int bufferThreshold = 10;
  static const Duration bufferFlushInterval = Duration(seconds: 5);
  // Packet Structure Offsets
  static const int packetLength = 24;
  static const int offsetLat = 0;
  static const int offsetLon = 4;
  static const int offsetSpeed = 8;
  static const int offsetTemp = 10;
  static const int offsetShock = 12;
  static const int offsetBattery = 14;
  static const int offsetInternalTemp = 16;
  static const int offsetTripState = 18;
  static const int offsetResetReason = 19;
  static const int offsetUptime = 20;

  // Multipliers
  static const double multiplierSpeed = 100.0;
  static const double multiplierTemp = 100.0;
  static const double multiplierBattery = 1000.0;

  // Simulation Settings
  static const Duration simulationInterval = Duration(seconds: 1);
  static const double simBaseLat = 37.7749;
  static const double simBaseLon = -122.4194;
  static const double simSpeedMin = 15.0;
  static const int simSpeedRange = 100;
  static const double simTempMin = 20.0;
  static const int simTempRange = 50;
  static const double simBatteryMin = 3.7;
  static const int simBatteryRange = 30;
  static const double simInternalTempMin = 45.0;
  static const int simInternalTempRange = 100;

  // Control Commands
  static const String cmdScan = "CMD:SCAN";
  static const String cmdIdentify = "CMD:IDENTIFY";
  static const String cmdReboot = "CMD:REBOOT";
  static const String cmdResetWifi = "CMD:RESET_WIFI";
  static const String scanEnd = "SCAN:END";
  static const String wifiPrefix = "WIFI:";
  static const String wifiConnectedPrefix = "WIFI:CONNECTED:";
  static const String wifiFailedPrefix = "WIFI:FAILED:";
}
