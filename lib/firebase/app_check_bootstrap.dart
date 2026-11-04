import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../services/meal_intelligence.dart';
import 'app_check_debug_stub.dart'
    if (dart.library.js_interop) 'app_check_debug_web.dart';

class AppCheckSettings {
  const AppCheckSettings({
    required this.isWeb,
    required this.platform,
    required this.isDebug,
    this.webSiteKey = '',
    this.webDebug = false,
  });

  factory AppCheckSettings.current() => AppCheckSettings(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
    isDebug: kDebugMode,
    webSiteKey: const String.fromEnvironment('FIREBASE_APP_CHECK_WEB_SITE_KEY'),
    webDebug: const bool.fromEnvironment('APP_CHECK_WEB_DEBUG'),
  );

  final bool isWeb;
  final TargetPlatform platform;
  final bool isDebug;
  final String webSiteKey;
  final bool webDebug;

  bool get usesAndroidDebug =>
      !isWeb && platform == TargetPlatform.android && isDebug;
  bool get usesWebDebug => isWeb && isDebug && webDebug;

  String? get configurationError {
    if (isWeb && webDebug && !isDebug) {
      return 'Bản phát hành không hỗ trợ App Check debug. Hãy dùng cấu hình App Check cho bản phát hành.';
    }
    if (isWeb && webSiteKey.trim().isEmpty) {
      return 'AI chưa được cấu hình trên bản web này. Cần đăng ký App Check cho ứng dụng web và đặt FIREBASE_APP_CHECK_WEB_SITE_KEY theo hướng dẫn Firebase AI Logic.';
    }
    if (!isWeb && platform != TargetPlatform.android) {
      return 'Phân tích AI hiện hỗ trợ Android và web. Hãy mở VetaLife trên một nền tảng được hỗ trợ.';
    }
    return null;
  }
}

typedef AppCheckActivation = Future<void> Function(AppCheckSettings settings);

/// Configure early after Firebase initialization. Configuration problems affect
/// AI availability; they do not turn a usable profile/journal into a boot error.
class AppCheckBootstrap {
  AppCheckBootstrap({
    required this.settings,
    AppCheckActivation? activate,
    void Function()? enableWebDebug,
    this.timeout = const Duration(seconds: 15),
  }) : _activate = activate ?? _activateFirebase,
       _enableWebDebug = enableWebDebug ?? enableWebAppCheckDebug;

  static final instance = AppCheckBootstrap(
    settings: AppCheckSettings.current(),
  );

  final AppCheckSettings settings;
  final AppCheckActivation _activate;
  final void Function() _enableWebDebug;
  final Duration timeout;
  Future<void>? _pending;
  bool _active = false;
  bool _webDebugPrepared = false;
  String? _lastError;

  Future<void> initializeWithFirebase(
    Future<void> Function() initialize,
  ) async {
    // Firebase Core Web can restore a cached App Check provider while it
    // initializes, before our explicit activate call. Set the debug flag first.
    _prepareWebDebug();
    await initialize();
    await configure();
  }

  void _prepareWebDebug() {
    if (!_webDebugPrepared &&
        settings.configurationError == null &&
        settings.usesWebDebug) {
      _enableWebDebug();
      _webDebugPrepared = true;
    }
  }

  Future<void> configure() {
    if (_active) return Future<void>.value();
    final error = settings.configurationError;
    if (error != null) {
      _lastError = error;
      return Future<void>.value();
    }
    return _pending ??= _activateSafely();
  }

  Future<void> _activateSafely() async {
    try {
      _prepareWebDebug();
      await _activate(settings).timeout(timeout);
      _active = true;
      _lastError = null;
    } catch (_) {
      _lastError = 'Chưa khởi tạo được App Check để dùng AI. Kiểm tra kết nối và cấu hình ứng dụng trong Firebase Console rồi thử lại.';
    } finally {
      _pending = null;
    }
  }

  Future<void> requireAiReady() async {
    await configure();
    if (!_active) {
      throw MealServiceException(
        _lastError ?? 'App Check chưa sẵn sàng để dùng AI.',
      );
    }
  }

  static Future<void> _activateFirebase(AppCheckSettings settings) async {
    await FirebaseAppCheck.instance.activate(
      providerWeb: settings.isWeb
          ? ReCaptchaV3Provider(settings.webSiteKey.trim())
          : null,
      providerAndroid: settings.usesAndroidDebug
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  }
}
