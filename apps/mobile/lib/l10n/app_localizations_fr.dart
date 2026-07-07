// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Rastreador de Última Milla';

  @override
  String get homeTab => 'Accueil';

  @override
  String get shipmentsTab => 'Expéditions';

  @override
  String get fleetTab => 'Flotte';

  @override
  String get settingsTab => 'Paramètres';

  @override
  String get offlineModeAlert =>
      'Mode hors ligne actif. Les modifications seront synchronisées plus tard.';

  @override
  String get driverScorecard => 'Carte de Score du Chauffeur';

  @override
  String get safetyScore => 'Score de Sécurité';

  @override
  String get batteryEfficiency => 'Efficacité de la Batterie';

  @override
  String get hardBraking => 'Freinage Brutal';

  @override
  String get speeding => 'Excès de Vitesse';

  @override
  String get maintenanceTitle => 'En Maintenance';

  @override
  String get maintenanceMessage =>
      'Nous effectuons actuellement une maintenance planifiée. Veuillez revenir plus tard.';

  @override
  String get retryButton => 'Vérifier le Statut';
}
