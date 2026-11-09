import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel(this.service);
  final NotificationService service;
  List<AppNotification> items = const [];
  NotificationPermission permission = NotificationPermission.notDetermined;
  bool isLoading = true;
  bool isBusy = false;
  String? errorMessage;
  AppNotification? latest;
  NotificationDestination? pendingDestination;
  bool _disposed = false;
  int _loadVersion = 0;
  StreamSubscription<AppNotification>? _messages;
  StreamSubscription<AppNotification>? _opened;

  int get unreadCount => items.where((item) => !item.isRead).length;

  Future<void> initialize() async {
    _messages ??= service.messages.listen(
      (item) {
        latest = item;
        unawaited(refresh());
      },
      onError: (Object _) {
        errorMessage = 'Chưa nhận hoặc lưu được thông báo. Hãy thử lại.';
        _notify();
      },
    );
    _opened ??= service.opened.listen((item) {
      pendingDestination = item.destination;
      unawaited(refresh());
    });
    try {
      permission = await service.initialize();
    } catch (_) {
      errorMessage = 'Chưa kết nối được thông báo. Hãy thử lại.';
    } finally {
      final connectionError = errorMessage;
      await refresh();
      errorMessage ??= connectionError;
      isLoading = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    final version = ++_loadVersion;
    try {
      final loaded = await service.loadHistory();
      if (_disposed || version != _loadVersion) return;
      items = loaded;
      errorMessage = null;
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      errorMessage = 'Chưa tải được lịch sử thông báo. Hãy thử lại.';
    }
    _notify();
  }

  Future<void> enable() async {
    if (isBusy || _disposed) return;
    isBusy = true;
    errorMessage = null;
    _notify();
    try {
      permission = await service.requestPermission();
    } catch (_) {
      errorMessage =
          'Chưa bật được thông báo. Kiểm tra kết nối và cấu hình thông báo.';
    } finally {
      isBusy = false;
      _notify();
    }
  }

  Future<void> open(AppNotification item) async {
    if (isBusy || _disposed) return;
    isBusy = true;
    _notify();
    try {
      await service.markRead(item);
      if (_disposed) return;
      pendingDestination = item.destination;
      await refresh();
    } catch (_) {
      errorMessage = 'Chưa mở được thông báo. Hãy thử lại.';
    } finally {
      isBusy = false;
      _notify();
    }
  }

  NotificationDestination? takeDestination() {
    final value = pendingDestination;
    pendingDestination = null;
    return value;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadVersion++;
    unawaited(_messages?.cancel());
    unawaited(_opened?.cancel());
    unawaited(service.dispose());
    super.dispose();
  }
}
