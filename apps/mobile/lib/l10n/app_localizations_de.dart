// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Letzte Meile Tracker';

  @override
  String get homeTab => 'Startseite';

  @override
  String get shipmentsTab => 'Lieferungen';

  @override
  String get fleetTab => 'Flotte';

  @override
  String get settingsTab => 'Einstellungen';

  @override
  String get offlineModeAlert =>
      'Offline-Modus aktiv. Änderungen werden später synchronisiert.';

  @override
  String get driverScorecard => 'Fahrerbewertung';

  @override
  String get safetyScore => 'Sicherheitsbewertung';

  @override
  String get batteryEfficiency => 'Batterieeffizienz';

  @override
  String get hardBraking => 'Starkes Bremsen';

  @override
  String get speeding => 'Geschwindigkeitsüberschreitung';

  @override
  String get maintenanceTitle => 'Wartungsarbeiten';

  @override
  String get maintenanceMessage =>
      'Wir führen derzeit geplante Wartungsarbeiten durch. Bitte versuchen Sie es bald wieder.';

  @override
  String get retryButton => 'Status Prüfen';
}
