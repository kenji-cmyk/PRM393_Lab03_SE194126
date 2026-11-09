import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/app_telemetry.dart';

import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._service, {this._telemetry = const NoopAppTelemetry()});
  final AppTelemetry _telemetry;
  final AuthService _service;
  StreamSubscription<String?>? _subscription;
  bool isLoading = true;
  bool isBusy = false;
  String? uid;
  String? errorMessage;
  bool _disposed = false;

  void init() {
    _subscription ??= _service.userChanges.listen(
      (value) {
        uid = value;
        unawaited(_telemetry.identify(value));
        isLoading = false;
        errorMessage = null;
        _notify();
      },
      onError: (Object error) {
        isLoading = false;
        errorMessage = 'Không thể kiểm tra phiên đăng nhập. Hãy thử lại.';
        _notify();
      },
    );
  }

  Future<void> signIn() => _perform(_service.signIn, signingIn: true);
  Future<void> signOut() => _perform(_service.signOut, signingIn: false);

  Future<void> _perform(
    Future<void> Function() action, {
    required bool signingIn,
  }) async {
    if (isBusy || _disposed) return;
    isBusy = true;
    errorMessage = null;
    _notify();
    try {
      await action();
      unawaited(
        _telemetry.event(
          signingIn ? 'login' : 'sign_out',
          parameters: signingIn ? {'method': 'google'} : const {},
        ),
      );
    } on SignInCancelled {
      errorMessage = 'Bạn đã hủy đăng nhập. Có thể thử lại bất cứ lúc nào.';
    } catch (_) {
      unawaited(_telemetry.handledError('auth'));
      errorMessage = signingIn
          ? 'Đăng nhập chưa thành công. Kiểm tra kết nối và cấu hình Google.'
          : 'Chưa đăng xuất được. Vui lòng thử lại.';
    } finally {
      isBusy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
