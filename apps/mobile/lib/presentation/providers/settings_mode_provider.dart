import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SettingsRole { driver, operations, admin }

class SettingsModeNotifier extends Notifier<SettingsRole> {
  @override
  SettingsRole build() {
    return SettingsRole.driver;
  }

  void setRole(SettingsRole role) {
    state = role;
  }
}

final settingsModeProvider =
    NotifierProvider<SettingsModeNotifier, SettingsRole>(
      SettingsModeNotifier.new,
    );
