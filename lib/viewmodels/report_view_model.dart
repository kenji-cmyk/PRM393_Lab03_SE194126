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
  List<SavedReport> history = const [];
  bool historyLoading = false;
  String? historyError;
  String? openingReportPath;
  Uint8List? _bytes;
  bool _disposed = false;
  int _generation = 0;
  int _historyGeneration = 0;
  bool get supportsHistory => !isPreview && _service is ReportArchive;
  bool get hasGeneratedReport => _bytes != null;
  bool get canOpen => _bytes != null && !isBusy && !isOpening;
  bool _current(int generation) => !_disposed && generation == _generation;

  Future<void> loadHistory() async {
    if (_disposed || !supportsHistory) return;
    final generation = ++_historyGeneration;
    historyLoading = true;
    historyError = null;
    notifyListeners();
    try {
      final reports = await (_service as ReportArchive).listRecent();
      if (_disposed || generation != _historyGeneration) return;
      history = List.unmodifiable(reports);
    } catch (error) {
      if (_disposed || generation != _historyGeneration) return;
      _onError?.call('report_history');
      historyError = error is ReportStorageException
          ? error.message
          : 'Chưa tải được báo cáo đã lưu. Kiểm tra kết nối và thử lại.';
    } finally {
      if (!_disposed && generation == _historyGeneration) {
        historyLoading = false;
        notifyListeners();
      }
    }
  }

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
      if (supportsHistory) unawaited(loadHistory());
    } on ReportCancelled {
      if (_current(generation)) message = 'Đã hủy tải báo cáo.';
    } catch (error) {
      if (_current(generation)) {
        _onError?.call('report_generate_upload');
        message = null;
        errorMessage = error is ReportStorageException ? error.message : 'Chưa tạo hoặc lưu được báo cáo. Kiểm tra kết nối, quyền truy cập và thử lại. PDF lưu trên cloud tối đa 5 MiB.';
        if (supportsHistory) unawaited(loadHistory());
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
      message = isPreview
          ? 'Đã hủy thao tác. Bạn có thể thử lại.'
          : 'Đã hủy chờ xử lý. Yêu cầu đã gửi có thể vẫn được lưu.';
      if (supportsHistory) unawaited(loadHistory());
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
    await _openReport(uploaded);
  }

  Future<void> openSaved(SavedReport saved) async {
    if (_disposed ||
        isBusy ||
        isOpening ||
        !supportsHistory ||
        !history.any((item) => item.report.path == saved.report.path)) {
      return;
    }
    await _openReport(saved.report);
  }

  Future<void> _openReport(UploadedReport? report) async {
    final generation = _generation;
    isOpening = true;
    openingReportPath = report?.path;
    errorMessage = null;
    notifyListeners();
    try {
      final bytes = report == null ? _bytes! : await _service.download(report);
      if (!_current(generation)) return;
      await _service.open(bytes);
      if (_current(generation)) _onEvent?.call('report_opened');
    } catch (error) {
      if (_current(generation)) {
        _onError?.call('report_open');
        errorMessage = error is ReportStorageException
            ? error.message
            : 'Chưa mở được PDF. Hãy kiểm tra kết nối và thử lại.';
      }
    } finally {
      if (_current(generation)) {
        isOpening = false;
        openingReportPath = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    ++_historyGeneration;
    _bytes = null;
    uploaded = null;
    history = const [];
    unawaited(_service.cancel().catchError((Object _) {}));
    super.dispose();
  }
}
