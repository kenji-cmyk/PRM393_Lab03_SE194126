import 'package:flutter/foundation.dart';

import '../models/lesson.dart';
import '../services/lesson_catalog_service.dart';
import '../services/lesson_progress_repository.dart';

enum LearningStage { home, progress, catalog, detail }

enum _LearningOperation { load, save }

class LearningViewModel extends ChangeNotifier {
  LearningViewModel({
    required this._repository,
    Future<LessonCatalog> Function()? loadCatalog,
    DateTime Function()? now,
  }) : _loadCatalog = loadCatalog ?? AssetLessonCatalog().load,
       _now = now ?? DateTime.now;

  final LessonProgressRepository _repository;
  final Future<LessonCatalog> Function() _loadCatalog;
  final DateTime Function() _now;
  LessonCatalog? _catalog;
  LearningStage _stage = LearningStage.home;
  LearningStage _catalogOrigin = LearningStage.home;
  String _selectedPartId = 'part-1';
  String? _selectedLessonId;
  final Map<String, LessonReadProgress> _read = {};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _progressReady = false;
  bool _disposed = false;
  bool _clearing = false;
  int _sessionGeneration = 0;
  int _loadGeneration = 0;
  Future<void>? _pendingSave;
  String? _errorMessage;
  _LearningOperation? _failedOperation;

  LearningStage get stage => _stage;
  LessonCatalog? get catalog => _catalog;
  String get selectedPartId => _selectedPartId;
  Lesson? get selectedLesson => _selectedLessonId == null
      ? null
      : _catalog?.lessonById(_selectedLessonId!);
  List<LessonReadProgress> get readProgress {
    final records = _read.values.toList()
      ..sort((a, b) {
        final date = b.readAt.compareTo(a.readAt);
        return date == 0 ? a.lessonId.compareTo(b.lessonId) : date;
      });
    return List.unmodifiable(records);
  }

  int get completedCoreCount =>
      _catalog?.lessons
          .where((lesson) => lesson.isCore && isRead(lesson.id))
          .length ??
      0;
  Lesson? get lastReadLesson {
    for (final item in readProgress) {
      final lesson = _catalog?.lessonById(item.lessonId);
      if (lesson != null) return lesson;
    }
    return null;
  }

  bool get isLoading => _isLoading;
  bool get progressReady => _progressReady;
  bool get isSaving => _isSaving || _clearing;
  String? get errorMessage => _errorMessage;
  bool isRead(String id) => _read.containsKey(id);
  bool get _canNavigate => !_disposed && !isSaving;
  bool _current(int session, int load) =>
      !_disposed &&
      !_clearing &&
      session == _sessionGeneration &&
      load == _loadGeneration;

  Future<void> initialize() async {
    if (!_canNavigate) return;
    final session = _sessionGeneration;
    final load = ++_loadGeneration;
    _isLoading = true;
    _progressReady = false;
    _errorMessage = null;
    _failedOperation = null;
    _notify();
    try {
      final catalogue = await _loadCatalog();
      if (!_current(session, load)) return;
      _catalog = catalogue;
      final progress = await _repository.load();
      if (!_current(session, load)) return;
      final records = <String, LessonReadProgress>{};
      for (final value in progress) {
        final validated = LessonReadProgress.fromJson(value.toJson());
        if (catalogue.lessonById(validated.lessonId) == null) {
          throw const FormatException('Progress has no matching lesson');
        }
        final existing = records[validated.lessonId];
        // Duplicate server or mock records can never inflate completion counts.
        if (existing == null || validated.readAt.isBefore(existing.readAt)) {
          records[validated.lessonId] = validated;
        }
      }
      _read
        ..clear()
        ..addAll(records);
      _progressReady = true;
    } catch (_) {
      if (!_current(session, load)) return;
      _failedOperation = _LearningOperation.load;
      _errorMessage = 'Chưa tải được bài học hoặc tiến độ đã đọc. Bạn vẫn có thể đọc nội dung đã tải; hãy thử lại để đồng bộ tiến độ.';
    } finally {
      if (_current(session, load)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> retry() => _failedOperation == _LearningOperation.save
      ? markSelectedRead()
      : initialize();

  void showHome() {
    if (!_canNavigate) return;
    _clearSaveFailure();
    _stage = LearningStage.home;
    _selectedLessonId = null;
    _notify();
  }

  void showProgress() {
    if (!_canNavigate) return;
    _clearSaveFailure();
    _stage = LearningStage.progress;
    _selectedLessonId = null;
    _notify();
  }

  void showCatalog() {
    if (!_canNavigate) return;
    _clearSaveFailure();
    if (_stage == LearningStage.progress || _stage == LearningStage.home) {
      _catalogOrigin = _stage;
    }
    _stage = LearningStage.catalog;
    _selectedLessonId = null;
    _notify();
  }

  void selectPart(String id) {
    if (!_canNavigate ||
        !(_catalog?.parts.any((part) => part.id == id) ?? false)) {
      return;
    }
    _selectedPartId = id;
    _notify();
  }

  void openLesson(String id) {
    if (!_canNavigate) return;
    final lesson = _catalog?.lessonById(id);
    if (lesson == null) return;
    if (_selectedLessonId != id) _clearSaveFailure();
    if (_stage == LearningStage.progress || _stage == LearningStage.home) {
      _catalogOrigin = _stage;
    }
    _selectedPartId = lesson.partId;
    _selectedLessonId = id;
    _stage = LearningStage.detail;
    _notify();
  }

  void back() {
    if (!_canNavigate) return;
    _clearSaveFailure();
    switch (_stage) {
      case LearningStage.detail:
        _stage = LearningStage.catalog;
        _selectedLessonId = null;
      case LearningStage.catalog:
        _stage = _catalogOrigin;
      case LearningStage.progress:
        _stage = LearningStage.home;
      case LearningStage.home:
        return;
    }
    _notify();
  }

  Future<void> markSelectedRead() async {
    if (!_canNavigate || _isLoading || _stage != LearningStage.detail) return;
    final lesson = selectedLesson;
    if (lesson == null || isRead(lesson.id)) return;
    if (!_progressReady) {
      _failedOperation = _LearningOperation.load;
      _errorMessage = 'Hãy thử tải lại tiến độ trước khi đánh dấu bài đã đọc.';
      _notify();
      return;
    }
    final session = _sessionGeneration;
    final progress = LessonReadProgress(
      lessonId: lesson.id,
      readAt: _now().toUtc(),
    );
    _isSaving = true;
    _errorMessage = null;
    _failedOperation = null;
    _notify();
    try {
      final pending = _repository.save(progress);
      _pendingSave = pending;
      await pending;
      if (_disposed || session != _sessionGeneration) return;
      _read[lesson.id] = progress;
    } catch (_) {
      if (_disposed || session != _sessionGeneration) return;
      _failedOperation = _LearningOperation.save;
      _errorMessage =
          'Chưa lưu được trạng thái đã đọc. Bài học vẫn được giữ; hãy thử lại.';
    } finally {
      _pendingSave = null;
      if (!_disposed && session == _sessionGeneration) {
        _isSaving = false;
        _notify();
      }
    }
  }

  Future<void> clearPreviewSession() async {
    if (_disposed || _clearing) return;
    _clearing = true;
    _sessionGeneration++;
    _loadGeneration++;
    _isLoading = false;
    _notify();
    try {
      // Complete any pending persistence before deleting it, even for an
      // injected repository that does not serialize operations itself.
      try {
        await _pendingSave;
      } catch (_) {
        /* clear still must run */
      }
      await _repository.clearPreview();
      if (_disposed) return;
      _read.clear();
      _progressReady = true;
      _stage = LearningStage.home;
      _selectedPartId = 'part-1';
      _selectedLessonId = null;
      _errorMessage = null;
      _failedOperation = null;
    } catch (_) {
      if (!_disposed) {
        _errorMessage = 'Chưa xóa được tiến độ xem thử. Hãy thử đăng xuất lại.';
      }
      throw StateError('Chưa xóa được tiến độ xem thử.');
    } finally {
      _clearing = false;
      _isSaving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _clearSaveFailure() {
    if (_failedOperation == _LearningOperation.save) {
      _failedOperation = null;
      _errorMessage = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionGeneration++;
    _loadGeneration++;
    super.dispose();
  }
}
