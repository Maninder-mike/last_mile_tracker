import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/presentation/app.dart';
import 'package:last_mile_tracker/presentation/pages/shipments/shipments_page.dart';
import 'package:last_mile_tracker/presentation/pages/settings/settings_page.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';

class AppLinkService {
  static final AppLinkService _instance = AppLinkService._internal();
  factory AppLinkService() => _instance;
  AppLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> init() async {
    try {
      // 1. Handle app launch link (cold start)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        FileLogger.log("AppLink: Initial link received: $initialUri");
        _handleUri(initialUri);
      }

      // 2. Handle links while the app is active
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          FileLogger.log("AppLink: Active link received: $uri");
          _handleUri(uri);
        },
        onError: (err) {
          FileLogger.log("AppLink: Error receiving link: $err");
        },
      );
    } catch (e) {
      FileLogger.log("AppLink: Initialization failed: $e");
    }
  }

  void _handleUri(Uri uri) {
    final path = uri.path.replaceAll('/', '');
    FileLogger.log("AppLink: Handling path '$path'");

    final context = navigatorKey.currentState?.context;
    if (context == null) {
      FileLogger.log("AppLink: Navigator context is not ready yet.");
      return;
    }

    if (path == 'shipments') {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (_) => const ShipmentsPage()));
    } else if (path == 'settings') {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (_) => const SettingsPage()));
    } else {
      FileLogger.log("AppLink: Unknown path '$path'");
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
