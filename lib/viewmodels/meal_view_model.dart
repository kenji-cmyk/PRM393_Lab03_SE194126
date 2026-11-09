import 'dart:async';

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../services/app_telemetry.dart';

import '../models/meal.dart';
import '../models/user_profile.dart';
import '../services/meal_intelligence.dart';
import '../services/meal_photo_picker.dart';
import '../services/meal_repository.dart';
import '../utils/calendar_date.dart';

enum MealStage {
  home,
  entry,
  recognizing,
  confirm,
  analyzing,
  result,
  error,
  journal,
}

enum _Operation { recognize, analyze, save }

class MealViewModel extends ChangeNotifier {
  MealViewModel({
    required this._repository,
    required this._intelligence,
    required this._photoPicker,
    required this._profile,
    DateTime Function()? now,
    String Function()? idFactory,
    this._telemetry = const NoopAppTelemetry(),
  }) : _now = now ?? DateTime.now,
       _idFactory = idFactory ?? _newId {
    _draft = _emptyDraft();
    _journalDate = calendarDate(_now());
  }

  final AppTelemetry _telemetry;
  final MealRepository _repository;
  final MealIntelligence _intelligence;
  final MealPhotoPicker _photoPicker;
  final UserProfile? Function() _profile;
  final DateTime Function() _now;
  final String Function() _idFactory;
  late MealDraft _draft;
  late DateTime _journalDate;
  MealStage _stage = MealStage.home;
  MealPhoto? _photo;
  MealRecognition? _recognition;
  MealAnalysis? _analysis;
  String? _errorMessage;
  String? _journalError;
  final Map<String, String> _errors = {};
  List<MealRecord> _records = [];
  bool _confirmed = false;
  bool _consent = false;
  bool _isSaving = false;
  bool _isLoadingJournal = false;
  bool _isPickingPhoto = false;
  bool _viewingSaved = false;
  bool _disposed = false;
  int _generation = 0;
  int _journalGeneration = 0;
  _Operation? _lastOperation;

  MealStage get stage => _stage;
  MealDraft get draft => _draft;
  MealPhoto? get photo => _photo;
  MealRecognition? get recognition => _recognition;
  MealAnalysis? get analysis => _analysis;
  String? get errorMessage => _errorMessage;
  Map<String, String> get errors => Map.unmodifiable(_errors);
  bool get confirmed => _confirmed;
  bool get consent => _consent;
  bool get isCloud => _intelligence.isCloud;
  bool get canRecognize => _intelligence.supportsImages;
  bool get isSaving => _isSaving;
  bool get isPickingPhoto => _isPickingPhoto;
  bool get isLoadingJournal => _isLoadingJournal;
  String? get journalError => _journalError;
  bool get viewingSaved => _viewingSaved;
  List<MealRecord> get records => List.unmodifiable(_records);
  DateTime get journalDate => _journalDate;
  List<MealRecord> get recordsForDate => List.unmodifiable(
    _records.where(
      (item) => calendarDate(item.draft.eatenAt.toLocal()) == _journalDate,
    ),
  );
  int get todayCount => _records
      .where(
        (item) =>
            calendarDate(item.draft.eatenAt.toLocal()) == calendarDate(_now()),
      )
      .length;

  bool get _canEdit =>
      !_disposed &&
      !_isSaving &&
      (_stage == MealStage.entry || _stage == MealStage.confirm);

  static String _newId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
        '${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }

  MealDraft _emptyDraft() {
    final now = _now();
    final type = now.hour < 10
        ? MealType.breakfast
        : now.hour < 15
        ? MealType.lunch
        : now.hour < 21
        ? MealType.dinner
        : MealType.snack;
    return MealDraft(
      id: _idFactory(),
      name: '',
      mealType: type,
      eatenAt: now,
      ingredients: const [],
    );
  }

  Future<void> initialize() async {
    final token = _generation;
    await _loadJournal();
    if (!_current(token) || _photoPicker is! DeviceMealPhotoPicker) return;
    try {
      final recovered = await _photoPicker.recoverLostPhoto();
      if (!_current(token) || recovered == null || _stage != MealStage.home) {
        return;
      }
      _photo = recovered;
      _stage = MealStage.entry;
      _notify();
    } catch (_) {
      // Recovery never sends or analyzes an image automatically.
      if (_current(token)) {
        _errorMessage =
            'Không khôi phục được ảnh cũ. Bạn có thể chụp lại khi ghi bữa ăn.';
        _notify();
      }
    }
  }

  void startNew() {
    if (_disposed || _isSaving) return;
    unawaited(_telemetry.event('meal_entry_start'));
    ++_generation;
    _draft = _emptyDraft();
    _photo = null;
    _recognition = null;
    _analysis = null;
    _confirmed = false;
    _consent = false;
    _viewingSaved = false;
    _errorMessage = null;
    _errors.clear();
    _stage = MealStage.entry;
    _notify();
  }

  void showHome() {
    if (_disposed || _isSaving) return;
    ++_generation;
    _stage = MealStage.home;
    _notify();
  }

  Future<void> openJournal() async {
    if (_disposed || _isSaving) return;
    ++_generation;
    _stage = MealStage.journal;
    unawaited(_telemetry.event('journal_open'));
    _journalDate = calendarDate(_now());
    _notify();
    await _loadJournal();
  }

  Future<void> _loadJournal() async {
    if (_disposed) return;
    final token = ++_journalGeneration;
    _isLoadingJournal = true;
    _journalError = null;
    _notify();
    try {
      final records = await _repository.load();
      if (_disposed || token != _journalGeneration) return;
      _records = records;
    } catch (_) {
      if (_disposed || token != _journalGeneration) return;
      unawaited(_telemetry.handledError('meal_load'));
      _journalError = 'Chưa tải được nhật ký. Kiểm tra kết nối và thử lại; dữ liệu hiện có không bị xóa.';
    } finally {
      if (!_disposed && token == _journalGeneration) {
        _isLoadingJournal = false;
        _notify();
      }
    }
  }

  void selectJournalDate(DateTime date) {
    if (_disposed || _isSaving) return;
    _journalDate = calendarDate(date);
    _notify();
  }

  void editDraft() {
    if (_disposed || _isSaving) return;
    ++_generation;
    _stage = MealStage.entry;
    _confirmed = false;
    _analysis = null;
    _viewingSaved = false;
    _errorMessage = null;
    _notify();
  }

  void _changed(MealDraft draft) {
    if (!_canEdit) return;
    _draft = draft;
    _confirmed = false;
    _analysis = null;
    _viewingSaved = false;
    _errorMessage = null;
    _errors.clear();
    _notify();
  }

  void updateName(String value) => _changed(_draft.copyWith(name: value));
  void updateNotes(String value) => _changed(_draft.copyWith(notes: value));
  void updateMealType(MealType value) =>
      _changed(_draft.copyWith(mealType: value));
  void updateEatenAt(DateTime value) =>
      _changed(_draft.copyWith(eatenAt: value));
  void addIngredient(MealIngredient ingredient) {
    if (_draft.ingredients.length >= 30) return;
    _changed(_draft.copyWith(ingredients: [..._draft.ingredients, ingredient]));
  }

  void updateIngredient(int index, MealIngredient ingredient) {
    if (index < 0 || index >= _draft.ingredients.length) return;
    final values = [..._draft.ingredients]..[index] = ingredient;
    _changed(_draft.copyWith(ingredients: values));
  }

  void removeIngredient(int index) {
    if (index < 0 || index >= _draft.ingredients.length) return;
    _changed(
      _draft.copyWith(ingredients: [..._draft.ingredients]..removeAt(index)),
    );
  }

  void setConfirmed(bool value) {
    if (!_canEdit) return;
    _confirmed = value;
    _errors.remove('confirmed');
    _notify();
  }

  void setConsent(bool value) {
    if (!_canEdit) return;
    _consent = value;
    _errors.remove('consent');
    _notify();
  }

  Future<void> pickPhoto(MealPhotoSource source) async {
    if (!_canEdit || _isPickingPhoto) return;
    final token = _generation;
    _isPickingPhoto = true;
    _notify();
    try {
      final selected = await _photoPicker.pick(source);
      if (!_current(token) || selected == null) return;
      _photo = selected;
      _recognition = null;
      _confirmed = false;
      _analysis = null;
      _consent = false;
      _errorMessage = null;
      _notify();
    } catch (error) {
      if (!_current(token)) return;
      _errorMessage = error is MealServiceException
          ? error.message
          : 'Không mở được ảnh. Bạn có thể thử lại hoặc nhập món bằng tay.';
      _notify();
    } finally {
      _isPickingPhoto = false;
      _notify();
    }
  }

  void removePhoto() {
    if (!_canEdit || _isPickingPhoto) return;
    _photo = null;
    _recognition = null;
    _confirmed = false;
    _analysis = null;
    _consent = false;
    _notify();
  }

  Future<void> recognizePhoto() async {
    if (!_canEdit || _photo == null || _isPickingPhoto) return;
    if (!canRecognize) {
      _errorMessage = 'Nhận diện ảnh cần chế độ cloud và dịch vụ Gemini. Bạn có thể nhập thành phần bằng tay.';
      _notify();
      return;
    }
    if (!_consent) {
      _errors['consent'] =
          'Xác nhận đồng ý gửi ảnh đến dịch vụ AI trước khi nhận diện.';
      _notify();
      return;
    }
    final token = ++_generation;
    final photo = _photo!;
    _stage = MealStage.recognizing;
    _lastOperation = _Operation.recognize;
    _errorMessage = null;
    _notify();
    try {
      final result = await _intelligence.recognize(photo);
      if (!_current(token)) return;
      _recognition = result;
      _draft = _draft.copyWith(
        name: _draft.name.trim().isEmpty ? result.mealName : _draft.name,
        ingredients: result.ingredients,
      );
      _confirmed = false;
      _analysis = null;
      _stage = MealStage.confirm;
    } catch (error) {
      if (_current(token)) _failure(error);
    }
    if (_current(token)) _notify();
  }

  bool _validate({required bool ingredients}) {
    _errors.clear();
    if (_draft.name.trim().isEmpty || _draft.name.trim().length > 160) {
      _errors['name'] = 'Nhập tên món từ 1 đến 160 ký tự.';
    }
    if (_draft.notes.length > 1000) {
      _errors['notes'] = 'Ghi chú tối đa 1.000 ký tự.';
    }
    if (_draft.eatenAt.isAfter(_now().add(const Duration(minutes: 5)))) {
      _errors['eatenAt'] = 'Chọn thời gian bữa ăn đã diễn ra.';
    }
    if (ingredients &&
        (_draft.ingredients.isEmpty ||
            _draft.ingredients.length > 30 ||
            _draft.ingredients.any(
              (item) =>
                  item.name.trim().isEmpty ||
                  item.name.length > 120 ||
                  item.amount.length > 100 ||
                  item.preparation.length > 120,
            ))) {
      _errors['ingredients'] = 'Thêm từ 1 đến 30 thành phần, mỗi tên tối đa 120 ký tự; kiểm tra lượng và cách chế biến.';
    }
    return _errors.isEmpty;
  }

  Future<void> reviewIngredients() async {
    if (!_canEdit || _isPickingPhoto) return;
    if (_validate(ingredients: false)) {
      _stage = MealStage.confirm;
      _confirmed = false;
      _errorMessage = null;
    }
    _notify();
  }

  Future<void> analyze() async {
    if (!_canEdit) return;
    _validate(ingredients: true);
    if (!_confirmed) {
      _errors['confirmed'] =
          'Xác nhận lại danh sách món và thành phần trước khi phân tích.';
    }
    if (isCloud && !_consent) {
      _errors['consent'] =
          'Đồng ý gửi món ăn và thông tin hồ sơ cần thiết đến Gemini.';
    }
    if (_errors.isNotEmpty) {
      _notify();
      return;
    }
    final profile = _profile();
    if (profile == null) {
      _errorMessage = 'Hồ sơ chưa sẵn sàng. Quay về Trang chủ để kiểm tra.';
      _notify();
      return;
    }
    final token = ++_generation;
    final draft = _draft;
    _stage = MealStage.analyzing;
    _lastOperation = _Operation.analyze;
    _errorMessage = null;
    _notify();
    try {
      final result = await _intelligence.analyze(draft, profile);
      if (!_current(token)) return;
      _analysis = result;
      _stage = MealStage.result;
      unawaited(_telemetry.event('meal_analysis_complete'));
    } catch (error) {
      if (_current(token)) _failure(error);
    }
    if (_current(token)) _notify();
  }

  Future<void> save() async {
    if (_disposed ||
        _isSaving ||
        _stage != MealStage.result ||
        _analysis == null ||
        _viewingSaved) {
      return;
    }
    final token = ++_generation;
    final record = MealRecord(
      id: _draft.id,
      draft: _draft,
      analysis: _analysis!,
      savedAt: _now(),
    );
    _isSaving = true;
    _lastOperation = _Operation.save;
    _errorMessage = null;
    // A concurrent load must not replace the journal after the save succeeds.
    ++_journalGeneration;
    _isLoadingJournal = false;
    _notify();
    try {
      await _repository.save(record);
      if (!_current(token)) return;
      _records = [..._records.where((item) => item.id != record.id), record]
        ..sort((a, b) => b.draft.eatenAt.compareTo(a.draft.eatenAt));
      _journalDate = calendarDate(record.draft.eatenAt.toLocal());
      _journalError = null;
      _viewingSaved = true;
      _stage = MealStage.journal;
      unawaited(
        _telemetry.event(
          'meal_saved',
          parameters: {'item_count': _records.length},
        ),
      );
    } catch (error) {
      if (_current(token)) {
        unawaited(_telemetry.handledError('meal_save'));
        _errorMessage = error is MealServiceException ? error.message : 'Chưa lưu được bữa ăn. Kết quả và bản nháp vẫn được giữ; thử lưu lại.';
      }
    } finally {
      if (_current(token)) {
        _isSaving = false;
        _notify();
      }
    }
  }

  Future<void> retry() async {
    if (_disposed || _isSaving) return;
    if (_stage == MealStage.journal) return _loadJournal();
    if (_lastOperation == _Operation.save) return save();
    if (_stage != MealStage.error) return;
    _stage = _lastOperation == _Operation.recognize
        ? MealStage.entry
        : MealStage.confirm;
    if (_lastOperation == _Operation.recognize) {
      await recognizePhoto();
    } else {
      await analyze();
    }
  }

  void showRecord(MealRecord record) {
    if (_disposed || _isSaving) return;
    unawaited(_telemetry.event('meal_detail_open'));
    ++_generation;
    _draft = record.draft;
    _analysis = record.analysis;
    _photo = null;
    _recognition = null;
    _consent = false;
    _confirmed = false;
    _viewingSaved = true;
    _errorMessage = null;
    _stage = MealStage.result;
    _notify();
  }

  Future<void> clearPreviewSession() async {
    if (_disposed || _isSaving) return;
    ++_generation;
    ++_journalGeneration;
    if (_photoPicker is DeviceMealPhotoPicker) {
      await _photoPicker.discardPendingPhoto();
    }
    await _repository.clear();
    if (_disposed) return;
    _records = [];
    _photo = null;
    _recognition = null;
    _analysis = null;
    _draft = _emptyDraft();
    _confirmed = false;
    _consent = false;
    _viewingSaved = false;
    _errorMessage = null;
    _journalError = null;
    _isLoadingJournal = false;
    _stage = MealStage.home;
    _notify();
  }

  void _failure(Object error) {
    unawaited(_telemetry.handledError('meal_analysis'));
    _errorMessage = error is MealServiceException ? error.message : 'Chưa tải được gợi ý. Kiểm tra kết nối và thử lại; bản nháp vẫn được giữ.';
    _stage = MealStage.error;
  }

  bool _current(int token) => !_disposed && token == _generation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    ++_journalGeneration;
    _records = [];
    _photo = null;
    _recognition = null;
    _analysis = null;
    _draft = _emptyDraft();
    super.dispose();
  }
}
