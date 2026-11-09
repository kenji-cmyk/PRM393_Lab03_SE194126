import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Operation codes only: never send raw exceptions or user content.
abstract class AppTelemetry {
  const AppTelemetry();
  Future<void> identify(String? uid);
  Future<void> event(String name, {Map<String, Object> parameters = const {}});
  Future<void> handledError(String operation);
}

class NoopAppTelemetry extends AppTelemetry {
  const NoopAppTelemetry();
  @override
  Future<void> identify(String? uid) async {}
  @override
  Future<void> event(
    String name, {
    Map<String, Object> parameters = const {},
  }) async {}
  @override
  Future<void> handledError(String operation) async {}
}

class FirebaseAppTelemetry extends AppTelemetry {
  FirebaseAppTelemetry({
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance,
       _crashlytics = kIsWeb
           ? null
           : crashlytics ?? FirebaseCrashlytics.instance;
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics? _crashlytics;
  Future<void> _queue = Future.value();
  static const events = {
    'login',
    'sign_out',
    'onboarding_start',
    'profile_saved',
    'meal_entry_start',
    'meal_analysis_complete',
    'meal_saved',
    'journal_open',
    'meal_detail_open',
    'progress_open',
    'lesson_catalog_open',
    'lesson_open',
    'lesson_read',
    'report_generated',
    'report_uploaded',
    'report_opened',
  };
  static const operations = {
    'auth',
    'profile_load',
    'profile_save',
    'meal_load',
    'meal_save',
    'meal_analysis',
    'lesson_load',
    'lesson_save',
    'report_upload',
    'notification',
    'remote_config',
    'flutter_framework',
    'platform_async',
    'diagnostic_handled',
  };
  // Serialize identity and events so an earlier login cannot finish after logout.
  Future<void> _safe(Future<void> Function() action) {
    _queue = _queue.then((_) async {
      try {
        await action().timeout(const Duration(seconds: 10));
      } catch (_) {
        /* Telemetry must not block UX. */
      }
    });
    return _queue;
  }

  Future<void> initialize() => _safe(() async {
    await Future.wait([
      _analytics.setAnalyticsCollectionEnabled(true),
      if (_crashlytics != null)
        _crashlytics.setCrashlyticsCollectionEnabled(true),
      if (_crashlytics != null) _crashlytics.setCustomKey('app_mode', 'cloud'),
    ]);
  });
  @override
  Future<void> identify(String? uid) => _safe(() async {
    await Future.wait([
      _analytics.setUserId(id: uid),
      if (_crashlytics != null) _crashlytics.setUserIdentifier(uid ?? ''),
    ]);
  });
  @override
  Future<void> event(String name, {Map<String, Object> parameters = const {}}) {
    if (!events.contains(name)) return Future.value();
    final safeParameters = parametersFor(name, parameters);
    return _safe(
      () => _analytics.logEvent(
        name: name,
        parameters: safeParameters.isEmpty ? null : safeParameters,
      ),
    );
  }

  /// Only bounded counts and fixed product enums cross the telemetry boundary.
  static Map<String, Object> parametersFor(
    String name,
    Map<String, Object> parameters,
  ) {
    if (!events.contains(name)) return const {};
    final count = parameters['item_count'];
    return {
      'flow': switch (name) {
        'login' || 'sign_out' => 'auth',
        'onboarding_start' || 'profile_saved' => 'onboarding',
        'progress_open' ||
        'lesson_catalog_open' ||
        'lesson_open' ||
        'lesson_read' => 'learning',
        'report_generated' || 'report_uploaded' || 'report_opened' => 'report',
        _ => 'meal',
      },
      if (name == 'login') 'method': 'google',
      if ((name == 'meal_saved' || name == 'lesson_read') &&
          count is int &&
          count >= 0 &&
          count <= 1000)
        'item_count': count,
    };
  }

  @override
  Future<void> handledError(String operation) {
    if (!operations.contains(operation)) return Future.value();
    return _safe(() async {
      await _crashlytics?.setCustomKey('last_operation', operation);
      await _crashlytics?.recordError(
        StateError('operation_failed:$operation'),
        StackTrace.empty,
        reason: operation,
        fatal: false,
      );
    });
  }

  bool get canTestCrash =>
      !kIsWeb &&
      !kReleaseMode &&
      const bool.fromEnvironment('ENABLE_CRASH_TEST');
  void testCrash() {
    if (canTestCrash) _crashlytics?.crash();
  }

  void installErrorHandlers() {
    if (kIsWeb) return;
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutter?.call(details);
      unawaited(handledError('flutter_framework'));
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(handledError('platform_async'));
      return previousPlatform?.call(error, stack) ?? false;
    };
  }
}
