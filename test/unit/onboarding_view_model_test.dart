import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/services/onboarding_repository.dart';
import 'package:vetalife/viewmodels/onboarding_view_model.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  UserProfile? stored;
  bool failLoad = false;
  bool failSave = false;
  bool failClear = false;
  int saveCalls = 0;
  Completer<void>? saveGate;
  Completer<UserProfile?>? loadGate;

  @override
  Future<UserProfile?> load() async {
    if (loadGate != null) return loadGate!.future;
    if (failLoad) throw StateError('offline');
    return stored;
  }

  @override
  Future<void> save(UserProfile profile) async {
    saveCalls++;
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw StateError('offline');
    stored = profile;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('local storage unavailable');
    stored = null;
  }
}

void main() {
  late FakeOnboardingRepository repository;
  late OnboardingViewModel model;

  setUp(() {
    repository = FakeOnboardingRepository();
    model = OnboardingViewModel(repository, now: () => DateTime(2026, 11, 3));
  });

  tearDown(() => model.dispose());

  Future<void> fillValidProfile() async {
    await model.init();
    model.start();
    model.updateDisplayName('  Trần Minh  ');
    model.updateBirthDate('04/11/2000');
    model.updateWeight('62,5');
    model.updateHeight('170.5');
  }

  test('first visit loads welcome, then uses profile before goals', () async {
    expect(model.stage, OnboardingStage.loading);
    await model.init();
    expect(model.stage, OnboardingStage.welcome);
    model.start();
    expect(model.stage, OnboardingStage.profile);
    expect(model.continueToGoals(), isFalse);
    expect(
      model.errors.keys,
      containsAll(['displayName', 'birthDate', 'weightKg', 'heightCm']),
    );
  });

  test(
    'valid input derives age and saves selected goal with decimal comma',
    () async {
      await fillValidProfile();
      expect(model.age, 25);
      expect(model.birthDate, DateTime(2000, 11, 4));
      expect(model.continueToGoals(), isTrue);
      model.selectGoal(HabitGoal.readDaily);
      await model.save();
      expect(model.stage, OnboardingStage.home);
      expect(model.profile!.displayName, 'Trần Minh');
      expect(repository.stored!.weightKg, 62.5);
      expect(repository.stored!.heightCm, 170.5);
      expect(repository.stored!.goal, HabitGoal.readDaily);
    },
  );

  test('invalid fields stay editable and do not erase another field', () async {
    await fillValidProfile();
    model.updateDisplayName('   ');
    model.updateBirthDate('31/02/2000');
    model.updateWeight('NaN');
    model.updateHeight('0');
    expect(model.continueToGoals(), isFalse);
    expect(model.errors, hasLength(4));
    model.updateDisplayName('Đặng Anh');
    expect(model.errors.containsKey('displayName'), isFalse);
    expect(model.errors, hasLength(3));
    expect(model.birthDateText, '31/02/2000');
    expect(model.weightText, 'NaN');
    expect(model.heightText, '0');
    expect(model.age, isNull);
  });

  test('future and impossible birth dates never yield an age', () async {
    await fillValidProfile();
    for (final value in [
      '04/11/2026',
      '29/02/2001',
      '31/04/2000',
      '01/13/2000',
    ]) {
      model.updateBirthDate(value);
      expect(model.birthDate, isNull);
      expect(model.age, isNull);
      expect(model.continueToGoals(), isFalse);
      expect(model.errors.keys, ['birthDate']);
    }
    model.updateBirthDate('03/11/2026');
    expect(model.age, 0);
    expect(model.continueToGoals(), isTrue);
  });

  test(
    'nonpositive, nonfinite and malformed measurements are rejected',
    () async {
      await fillValidProfile();
      for (final value in [
        '0',
        '-1',
        'NaN',
        'Infinity',
        '1e999',
        '1,2,3',
        'text',
      ]) {
        model.updateWeight(value);
        model.updateHeight(value);
        expect(model.continueToGoals(), isFalse);
        expect(model.errors.keys, containsAll(['weightKg', 'heightCm']));
      }
      model.updateWeight('0,25');
      model.updateHeight('1.25');
      expect(model.continueToGoals(), isTrue);
    },
  );

  test('back navigation retains every field and goal choice', () async {
    await fillValidProfile();
    model.continueToGoals();
    model.selectGoal(HabitGoal.recordMeals);
    model.back();
    expect(model.stage, OnboardingStage.profile);
    model.back();
    expect(model.stage, OnboardingStage.welcome);
    model.start();
    expect(model.displayName, '  Trần Minh  ');
    expect(model.birthDateText, '04/11/2000');
    expect(model.weightText, '62,5');
    expect(model.heightText, '170.5');
    expect(model.selectedGoal, HabitGoal.recordMeals);
  });

  test('save failure retains draft and retries successfully', () async {
    await fillValidProfile();
    model.continueToGoals();
    repository.failSave = true;
    await model.save();
    expect(model.stage, OnboardingStage.goals);
    expect(model.isSaving, isFalse);
    expect(model.errorMessage, isNotNull);
    expect(model.profile, isNull);
    expect(model.weightText, '62,5');
    repository.failSave = false;
    await model.save();
    expect(model.stage, OnboardingStage.home);
    expect(model.errorMessage, isNull);
    expect(repository.saveCalls, 2);
  });

  test(
    'duplicate save and navigation cannot change a pending submission',
    () async {
      await fillValidProfile();
      model.continueToGoals();
      repository.saveGate = Completer<void>();
      final saving = model.save();
      expect(model.isSaving, isTrue);
      await model.save();
      model.back();
      model.updateDisplayName('Changed');
      model.selectGoal(HabitGoal.readDaily);
      expect(repository.saveCalls, 1);
      expect(model.stage, OnboardingStage.goals);
      expect(model.displayName, '  Trần Minh  ');
      expect(model.selectedGoal, HabitGoal.addVegetables);
      repository.saveGate!.complete();
      await saving;
      expect(model.stage, OnboardingStage.home);
      expect(model.isSaving, isFalse);
    },
  );

  test(
    'load error has retry and existing saved profile resumes home',
    () async {
      repository.failLoad = true;
      await model.init();
      expect(model.stage, OnboardingStage.error);
      expect(model.errorMessage, isNotNull);
      repository.failLoad = false;
      repository.stored = UserProfile(
        displayName: 'Nguyễn An',
        birthDate: DateTime(1995, 2, 28),
        weightKg: 60,
        heightCm: 165,
        goal: HabitGoal.recordMeals,
      );
      await model.init();
      expect(model.stage, OnboardingStage.home);
      expect(model.profile!.displayName, 'Nguyễn An');
      expect(model.errorMessage, isNull);
      model.editProfile();
      expect(model.stage, OnboardingStage.profile);
      expect(model.birthDateText, '28/02/1995');
      expect(model.selectedGoal, HabitGoal.recordMeals);
      model.back();
      expect(model.stage, OnboardingStage.home);
    },
  );

  test('future stored date is treated as invalid load with recovery', () async {
    repository.stored = UserProfile(
      displayName: 'Nguyễn An',
      birthDate: DateTime(2026, 11, 4),
      weightKg: 60,
      heightCm: 165,
      goal: HabitGoal.recordMeals,
    );
    await model.init();
    expect(model.stage, OnboardingStage.error);
    expect(model.profile, isNull);
    repository.stored = null;
    await model.init();
    expect(model.stage, OnboardingStage.welcome);
  });

  test(
    'reset clears personal data and ignores a previous account load',
    () async {
      repository.loadGate = Completer<UserProfile?>();
      final loading = model.init();
      model.reset();
      repository.loadGate!.complete(
        UserProfile(
          displayName: 'Previous account',
          birthDate: DateTime(2000),
          weightKg: 60,
          heightCm: 165,
          goal: HabitGoal.recordMeals,
        ),
      );
      await loading;
      expect(model.stage, OnboardingStage.welcome);
      expect(model.profile, isNull);
      expect(model.displayName, isEmpty);
      expect(model.birthDateText, isEmpty);
      expect(model.weightText, isEmpty);
      expect(model.heightText, isEmpty);
    },
  );

  test(
    'reset during save prevents stale success from exposing private data',
    () async {
      await fillValidProfile();
      model.continueToGoals();
      repository.saveGate = Completer<void>();
      final saving = model.save();
      model.reset();
      repository.saveGate!.complete();
      await saving;
      expect(model.stage, OnboardingStage.welcome);
      expect(model.profile, isNull);
      expect(model.isSaving, isFalse);
    },
  );

  test(
    'ending preview session clears local persistence and private draft',
    () async {
      await fillValidProfile();
      model.continueToGoals();
      await model.save();
      await model.clearPreviewSession();
      expect(repository.stored, isNull);
      expect(model.stage, OnboardingStage.welcome);
      expect(model.profile, isNull);
      expect(model.displayName, isEmpty);
      expect(model.birthDateText, isEmpty);
      expect(model.weightText, isEmpty);
      expect(model.heightText, isEmpty);
      expect(model.isSaving, isFalse);
      expect(model.errorMessage, isNull);
    },
  );

  test(
    'failed preview session cleanup retains home and supports retry',
    () async {
      await fillValidProfile();
      model.continueToGoals();
      await model.save();
      repository.failClear = true;
      await model.clearPreviewSession();
      expect(model.stage, OnboardingStage.home);
      expect(model.profile!.displayName, 'Trần Minh');
      expect(repository.stored, isNotNull);
      expect(model.isSaving, isFalse);
      expect(
        model.errorMessage,
        'Chưa xóa được phiên xem thử. Vui lòng thử lại.',
      );
      repository.failClear = false;
      await model.clearPreviewSession();
      expect(model.stage, OnboardingStage.welcome);
      expect(model.profile, isNull);
    },
  );
}
