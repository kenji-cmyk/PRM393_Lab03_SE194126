import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

abstract interface class AppSettingsSource {
  Future<Map<String, bool>> fetch();
}

class FirebaseAppSettingsSource implements AppSettingsSource {
  FirebaseAppSettingsSource({FirebaseRemoteConfig? remoteConfig})
    : _remote = remoteConfig ?? FirebaseRemoteConfig.instance;
  final FirebaseRemoteConfig _remote;
  @override
  Future<Map<String, bool>> fetch() async {
    await _remote.setDefaults(AppSettings.defaults);
    await _remote.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 12),
      ),
    );
    await _remote.fetchAndActivate();
    return {
      for (final key in AppSettings.defaults.keys) key: _remote.getBool(key),
    };
  }
}

class AppSettings extends ChangeNotifier {
  AppSettings({this._source});
  AppSettings.cloud() : _source = FirebaseAppSettingsSource();
  static const defaults = {
    'learning_enabled': true,
    'report_export_enabled': true,
  };
  final AppSettingsSource? _source;
  Map<String, bool> _values = Map.of(defaults);
  bool _disposed = false;
  bool isLoading = false;
  String? errorMessage;
  DateTime? lastFetchedAt;
  bool get learningEnabled => _values['learning_enabled']!;
  bool get reportExportEnabled => _values['report_export_enabled']!;
  bool get isCloud => _source != null;
  Future<void> initialize() => refresh();
  Future<void> refresh() async {
    if (_disposed || isLoading || _source == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final values = await _source.fetch();
      if (_disposed) return;
      _values = {
        for (final key in defaults.keys) key: values[key] ?? _values[key]!,
      };
      lastFetchedAt = DateTime.now();
    } catch (_) {
      if (_disposed) return;
      errorMessage = 'Chưa tải được cấu hình. Ứng dụng giữ cấu hình hiện có; bạn có thể thử lại.';
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
