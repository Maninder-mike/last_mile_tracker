class BleConstants {
  static const String deviceName = "Last-Mile-";

  // Environmental Sensing Service
  static const String serviceUuid = "181A";

  // Characteristics
  static const String tempCharUuid = "2A6E";
  static const String locationCharUuid =
      "2A67"; // We re-purpose this for packed data
}
