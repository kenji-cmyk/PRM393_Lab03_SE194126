import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/report_service.dart';

class ReportViewModel extends ChangeNotifier {
  ReportViewModel({
    required this._service,
    required this._snapshot,
    required this.isPreview,
    this._onEvent,
    this._onError,
  });

  final ReportService _service;
  final Future<ReportData> Function() _snapshot;
  final void Function(String)? _onEvent;
  final void Function(String operation)? _onError;
  final bool isPreview;
  bool isBusy = false;
  bool isOpening = false;
  double progress = 0;
  String? message;
  String? errorMessage;
  UploadedReport? uploaded;
  Uint8List? _bytes;
  bool _disposed = false;
  int _generation = 0;
  bool get canOpen => _bytes != null && !isBusy && !isOpening;
  bool _current(int generation) => !_disposed && generation == _generation;

  Future<void> generate() async {
    if (isBusy || isOpening || _disposed) return;
    final generation = ++_generation;
    isBusy = true;
    progress = 0;
    message = 'Đang tạo báo cáo từ dữ liệu đã lưu…';
    errorMessage = null;
    uploaded = null;
    _bytes = null;
    notifyListeners();
    try {
      final data = await _snapshot();
      if (!_current(generation)) return;
      final bytes = await _service.generate(data);
      if (!_current(generation)) return;
      _onEvent?.call('report_generated');
      if (!isPreview) {
        message = 'Đang tải báo cáo lên cloud…';
        notifyListeners();
        final result = await _service.upload(bytes, (value) {
          if (_current(generation)) {
            progress = value.clamp(0, 1);
            notifyListeners();
          }
        });
        if (!_current(generation)) return;
        uploaded = result;
        _onEvent?.call('report_uploaded');
      }
      _bytes = bytes;
      message = isPreview
          ? 'Đã tạo PDF xem thử. Chưa tải lên cloud.'
          : 'Đã lưu báo cáo riêng tư trên cloud.';
    } on ReportCancelled {
      if (_current(generation)) message = 'Đã hủy tải báo cáo.';
    } catch (_) {
      if (_current(generation)) {
        _onError?.call('report_generate_upload');
        message = null;
        errorMessage = 'Chưa tạo hoặc tải được báo cáo. Kiểm tra kết nối và thử lại. Cloudinary cần được cấu hình cho dự án.';
      }
    } finally {
      if (_current(generation)) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<void> cancel() async {
    if (!isBusy || _disposed) return;
    ++_generation;
    // Keep the action locked until the active upload has acknowledged cancel.
    try {
      await _service.cancel();
      if (_disposed) return;
      message = 'Đã hủy thao tác. Bạn có thể thử lại.';
    } catch (_) {
      if (_disposed) return;
      _onError?.call('report_cancel');
      errorMessage = 'Chưa xác nhận được hủy tải. Hãy kiểm tra lại kết nối.';
    } finally {
      if (!_disposed) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<void> open() async {
    if (!canOpen || _disposed) return;
    final generation = _generation;
    isOpening = true;
    errorMessage = null;
    notifyListeners();
    try {
      final bytes = uploaded == null
          ? _bytes!
          : await _service.download(uploaded!);
      if (!_current(generation)) return;
      await _service.open(bytes);
      if (_current(generation)) _onEvent?.call('report_opened');
    } catch (_) {
      if (_current(generation)) {
        _onError?.call('report_open');
        errorMessage = 'Chưa mở được PDF. Hãy kiểm tra kết nối và thử lại.';
      }
    } finally {
      if (_current(generation)) {
        isOpening = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _bytes = null;
    uploaded = null;
    unawaited(_service.cancel().catchError((Object _) {}));
    super.dispose();
  }
}
