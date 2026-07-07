// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '最后一公里追踪器';

  @override
  String get homeTab => '首页';

  @override
  String get shipmentsTab => '货运';

  @override
  String get fleetTab => '车队';

  @override
  String get settingsTab => '设置';

  @override
  String get offlineModeAlert => '离线模式已激活。更改将在稍后同步。';

  @override
  String get driverScorecard => '驾驶员评分卡';

  @override
  String get safetyScore => '安全得分';

  @override
  String get batteryEfficiency => '电池效率';

  @override
  String get hardBraking => '急刹车事件';

  @override
  String get speeding => '超速事件';

  @override
  String get maintenanceTitle => '系统维护中';

  @override
  String get maintenanceMessage => '我们目前正在进行例行维护。请稍后再试。';

  @override
  String get retryButton => '检查状态';
}
