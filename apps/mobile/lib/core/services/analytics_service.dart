import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Firebase Analytics tracking.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Logs a custom event.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics: Logged event $name');
    } catch (e) {
      debugPrint('Analytics: Failed to log event $name: $e');
    }
  }

  /// Logs when a screen is viewed.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      debugPrint('Analytics: Logged screen view $screenName');
    } catch (e) {
      debugPrint('Analytics: Failed to log screen view $screenName: $e');
    }
  }

  /// Logs app open event.
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  /// Sets user ID for tracking.
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  /// Sets user properties for segmentation.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
