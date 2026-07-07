// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Rastreador de Última Milla';

  @override
  String get homeTab => 'Inicio';

  @override
  String get shipmentsTab => 'Envíos';

  @override
  String get fleetTab => 'Flota';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get offlineModeAlert =>
      'Modo sin conexión activo. Los cambios se sincronizarán más tarde.';

  @override
  String get driverScorecard => 'Puntuación del Conductor';

  @override
  String get safetyScore => 'Puntuación de Seguridad';

  @override
  String get batteryEfficiency => 'Eficiencia de Batería';

  @override
  String get hardBraking => 'Frenadas Bruscas';

  @override
  String get speeding => 'Excesos de Velocidad';

  @override
  String get maintenanceTitle => 'En Mantenimiento';

  @override
  String get maintenanceMessage =>
      'Actualmente estamos realizando tareas de mantenimiento programadas. Por favor, vuelva a intentarlo pronto.';

  @override
  String get retryButton => 'Comprobar Estado';
}
