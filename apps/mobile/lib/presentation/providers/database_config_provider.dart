import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:last_mile_tracker/core/config/supabase_config.dart';

class DatabaseConfig {
  final String url;
  final String anonKey;
  final bool isDemoMode;

  DatabaseConfig({
    required this.url,
    required this.anonKey,
    required this.isDemoMode,
  });

  DatabaseConfig copyWith({
    String? url,
    String? anonKey,
    bool? isDemoMode,
  }) {
    return DatabaseConfig(
      url: url ?? this.url,
      anonKey: anonKey ?? this.anonKey,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }
}

class DatabaseConfigNotifier extends Notifier<DatabaseConfig> {
  static const _urlKey = 'custom_supabase_url';
  static const _anonKey = 'custom_supabase_anon_key';
  static const _demoKey = 'custom_supabase_is_demo';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  DatabaseConfig build() {
    Future.microtask(_loadConfig);
    return DatabaseConfig(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      isDemoMode: true, // Default to true so first-time installs boot in Demo Mode
    );
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    String? savedUrl = await _secureStorage.read(key: _urlKey);
    String? savedAnon = await _secureStorage.read(key: _anonKey);

    // Migration logic: move legacy unencrypted SharedPreferences keys to SecureStorage
    if (savedUrl == null || savedAnon == null) {
      final legacyUrl = prefs.getString(_urlKey);
      final legacyAnon = prefs.getString(_anonKey);
      if (legacyUrl != null) {
        savedUrl = legacyUrl;
        await _secureStorage.write(key: _urlKey, value: legacyUrl);
        await prefs.remove(_urlKey);
      }
      if (legacyAnon != null) {
        savedAnon = legacyAnon;
        await _secureStorage.write(key: _anonKey, value: legacyAnon);
        await prefs.remove(_anonKey);
      }
    }

    final url = savedUrl ?? SupabaseConfig.url;
    final anonKey = savedAnon ?? SupabaseConfig.anonKey;

    final isPlaceholder = url.isEmpty ||
        url == 'https://your-project.supabase.co' ||
        anonKey.isEmpty;

    final savedDemo = prefs.getBool(_demoKey);
    final isDemoMode = savedDemo ?? isPlaceholder;

    state = DatabaseConfig(
      url: url,
      anonKey: anonKey,
      isDemoMode: isDemoMode,
    );
  }

  Future<void> setConfig({
    required String url,
    required String anonKey,
  }) async {
    await _secureStorage.write(key: _urlKey, value: url);
    await _secureStorage.write(key: _anonKey, value: anonKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoKey, false);

    state = DatabaseConfig(
      url: url,
      anonKey: anonKey,
      isDemoMode: false,
    );
  }

  Future<void> enableDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoKey, true);
    state = state.copyWith(isDemoMode: true);
  }

  Future<void> clearConfig() async {
    await _secureStorage.delete(key: _urlKey);
    await _secureStorage.delete(key: _anonKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoKey, true);

    state = DatabaseConfig(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      isDemoMode: true,
    );
  }
}

final databaseConfigProvider =
    NotifierProvider<DatabaseConfigNotifier, DatabaseConfig>(() {
  return DatabaseConfigNotifier();
});
