import 'package:flutter/foundation.dart';

import '../models/habit_goal.dart';
import '../models/user_profile.dart';
import '../services/onboarding_repository.dart';
import '../utils/calendar_date.dart';

enum OnboardingStage { loading, welcome, profile, goals, home, error }

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final OnboardingRepository _repository;
  final DateTime Function() _now;

  OnboardingStage _stage = OnboardingStage.loading;
  String _displayName = '';
  String _birthDateText = '';
  String _weightText = '';
  String _heightText = '';
  final Map<String, String> _errors = {};
  HabitGoal _selectedGoal = HabitGoal.addVegetables;
  UserProfile? _profile;
  bool _isSaving = false;
  bool _isInitializing = false;
  String? _errorMessage;
  bool _disposed = false;
  int _generation = 0;

  OnboardingStage get stage => _stage;
  String get displayName => _displayName;
  String get birthDateText => _birthDateText;
  String get weightText => _weightText;
  String get heightText => _heightText;
  Map<String, String> get errors => Map.unmodifiable(_errors);
  HabitGoal get selectedGoal => _selectedGoal;
  UserProfile? get profile => _profile;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  DateTime get today => calendarDate(_now());

  DateTime? get birthDate {
    final value = parseCalendarDate(_birthDateText, iso: false);
    return value == null || value.isAfter(today) ? null : value;
  }

  int? get age {
    final date = birthDate;
    return date == null ? null : ageOn(date, today);
  }

  Future<void> init() async {
    if (_disposed || _isInitializing || _isSaving) return;
    final generation = ++_generation;
    _isInitializing = true;
    _stage = OnboardingStage.loading;
    _errorMessage = null;
    _notify();
    try {
      final stored = await _repository.load();
      if (!_isCurrent(generation)) return;
      if (stored != null && stored.birthDate.isAfter(today)) {
        throw const FormatException('Profile birth date is in the future');
      }
      _profile = stored;
      if (stored != null) _populateDraft(stored);
      _stage = stored == null ? OnboardingStage.welcome : OnboardingStage.home;
    } catch (_) {
      if (!_isCurrent(generation)) return;
      _stage = OnboardingStage.error;
      _errorMessage =
          'Không thể tải hồ sơ. Vui lòng kiểm tra kết nối và thử lại.';
    } finally {
      if (_isCurrent(generation)) {
        _isInitializing = false;
        _notify();
      }
    }
  }

  void start() {
    if (_disposed || _isSaving || _stage != OnboardingStage.welcome) return;
    _stage = OnboardingStage.profile;
    _notify();
  }

  void updateDisplayName(String value) {
    if (_disposed || _isSaving) return;
    _displayName = value;
    _fieldChanged('displayName');
  }

  void updateBirthDate(String value) {
    if (_disposed || _isSaving) return;
    _birthDateText = value;
    _fieldChanged('birthDate');
  }

  void updateWeight(String value) {
    if (_disposed || _isSaving) return;
    _weightText = value;
    _fieldChanged('weightKg');
  }

  void updateHeight(String value) {
    if (_disposed || _isSaving) return;
    _heightText = value;
    _fieldChanged('heightCm');
  }

  bool continueToGoals() {
    if (_disposed || _isSaving || _stage != OnboardingStage.profile) {
      return false;
    }
    final valid = _validate();
    if (valid) _stage = OnboardingStage.goals;
    _notify();
    return valid;
  }

  void selectGoal(HabitGoal goal) {
    if (_disposed || _isSaving) return;
    _selectedGoal = goal;
    _errorMessage = null;
    _notify();
  }

  void back() {
    if (_disposed || _isSaving) return;
    switch (_stage) {
      case OnboardingStage.goals:
        _stage = OnboardingStage.profile;
      case OnboardingStage.profile:
        _stage = _profile == null
            ? OnboardingStage.welcome
            : OnboardingStage.home;
      default:
        return;
    }
    _errorMessage = null;
    _notify();
  }

  Future<void> save() async {
    if (_disposed || _isSaving || _stage != OnboardingStage.goals) return;
    if (!_validate()) {
      _stage = OnboardingStage.profile;
      _notify();
      return;
    }
    final value = UserProfile(
      displayName: _displayName,
      birthDate: birthDate!,
      weightKg: _positiveNumber(_weightText)!,
      heightCm: _positiveNumber(_heightText)!,
      goal: _selectedGoal,
    );
    final generation = ++_generation;
    _isSaving = true;
    _errorMessage = null;
    _notify();
    try {
      await _repository.save(value);
      if (!_isCurrent(generation)) return;
      _profile = value;
      _stage = OnboardingStage.home;
    } catch (_) {
      if (!_isCurrent(generation)) return;
      _errorMessage =
          'Chưa lưu được hồ sơ. Thông tin vẫn được giữ, hãy thử lại.';
    } finally {
      if (_isCurrent(generation)) {
        _isSaving = false;
        _notify();
      }
    }
  }

  void editProfile() {
    if (_disposed || _isSaving || _profile == null) return;
    _populateDraft(_profile!);
    _errors.clear();
    _errorMessage = null;
    _stage = OnboardingStage.profile;
    _notify();
  }

  /// Ends an explicitly local preview session. Cloud sign-out must use Auth
  /// instead, preserving the account's remote profile.
  Future<void> clearPreviewSession() async {
    if (_disposed || _isSaving || _isInitializing) return;
    final generation = ++_generation;
    _isSaving = true;
    _errorMessage = null;
    _notify();
    try {
      await _repository.clear();
      if (!_isCurrent(generation)) return;
      reset();
    } catch (_) {
      if (!_isCurrent(generation)) return;
      _errorMessage = 'Chưa xóa được phiên xem thử. Vui lòng thử lại.';
    } finally {
      if (_isCurrent(generation)) {
        _isSaving = false;
        _notify();
      }
    }
  }

  /// Clears this account's in-memory state without deleting cloud profile data.
  void reset() {
    if (_disposed) return;
    _generation++;
    _isInitializing = false;
    _isSaving = false;
    _profile = null;
    _displayName = '';
    _birthDateText = '';
    _weightText = '';
    _heightText = '';
    _selectedGoal = HabitGoal.addVegetables;
    _errors.clear();
    _errorMessage = null;
    _stage = OnboardingStage.welcome;
    _notify();
  }

  void _populateDraft(UserProfile value) {
    _displayName = value.displayName;
    _birthDateText = formatCalendarDate(value.birthDate, iso: false);
    _weightText = value.weightKg.toString();
    _heightText = value.heightCm.toString();
    _selectedGoal = value.goal;
  }

  bool _validate() {
    _errors.clear();
    _errorMessage = null;
    if (_displayName.trim().isEmpty) {
      _errors['displayName'] = 'Vui lòng nhập họ và tên.';
    }
    if (birthDate == null) {
      _errors['birthDate'] = _birthDateText.trim().isEmpty
          ? 'Vui lòng nhập ngày sinh.'
          : 'Nhập ngày hợp lệ, không sau hôm nay.';
    }
    if (_positiveNumber(_weightText) == null) {
      _errors['weightKg'] = 'Nhập cân nặng lớn hơn 0.';
    }
    if (_positiveNumber(_heightText) == null) {
      _errors['heightCm'] = 'Nhập chiều cao lớn hơn 0.';
    }
    return _errors.isEmpty;
  }

  double? _positiveNumber(String value) {
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    return number != null && number.isFinite && number > 0 ? number : null;
  }

  void _fieldChanged(String field) {
    _errors.remove(field);
    _errorMessage = null;
    _notify();
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
