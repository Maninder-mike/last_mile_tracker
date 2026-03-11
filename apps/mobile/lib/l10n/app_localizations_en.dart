// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Last Mile Tracker';

  @override
  String get homeTab => 'Home';

  @override
  String get shipmentsTab => 'Shipments';

  @override
  String get fleetTab => 'Fleet';

  @override
  String get settingsTab => 'Settings';

  @override
  String get offlineModeAlert =>
      'Offline mode active. Changes will sync later.';

  @override
  String get driverScorecard => 'Driver Scorecard';

  @override
  String get safetyScore => 'Safety Score';

  @override
  String get batteryEfficiency => 'Battery Efficiency';

  @override
  String get hardBraking => 'Hard Braking';

  @override
  String get speeding => 'Speeding Events';
}
