import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/meal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/services/meal_intelligence.dart';
import 'package:vetalife/services/meal_photo_picker.dart';
import 'package:vetalife/services/meal_repository.dart';
import 'package:vetalife/viewmodels/meal_view_model.dart';

final _now = DateTime(2026, 11, 3, 12, 30);
final _profile = UserProfile(
  displayName: 'Nguyễn Ánh',
  birthDate: DateTime(2000, 2, 29),
  weightKg: 62.5,
  heightCm: 170.5,
  goal: HabitGoal.addVegetables,
);

MealAnalysis _analysis() => MealAnalysis(
  title: 'Một góc nhìn từ sách',
  summary: 'Nhận xét từ thành phần đã xác nhận.',
  highlights: const ['Có đậu hũ.'],
  improvements: const ['Luân phiên loại rau.'],
  profileNote: 'Theo mục tiêu đã chọn.',
  limitations: const ['Chưa biết khẩu phần.'],
  references: const [],
  healthConnections: const [],
  mode: 'localBook',
);

MealRecognition _recognition() => MealRecognition(
  mealName: 'Đậu hũ và rau',
  ingredients: const [MealIngredient(name: 'Đậu hũ')],
  ocrText: 'MENU: nước tương, mè',
  warnings: const ['Ảnh không cho biết thành phần ẩn.'],
);

MealPhoto _photo() => MealPhoto(
  bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0x00]),
  mimeType: 'image/jpeg',
  fileName: 'meal.jpg',
);

class _Repository implements MealRepository {
  final records = <MealRecord>[];
  int saves = 0;
  bool failSave = false;
  bool failLoad = false;
  Completer<void>? pendingSave;
  Completer<List<MealRecord>>? pendingLoad;

  @override
  Future<List<MealRecord>> load() async {
    if (failLoad) throw StateError('offline');
    if (pendingLoad != null) return pendingLoad!.future;
    return [...records];
  }

  @override
  Future<void> save(MealRecord record) async {
    saves++;
    if (failSave) throw StateError('offline');
    if (pendingSave != null) await pendingSave!.future;
    records.removeWhere((item) => item.id == record.id);
    records.add(record);
  }

  @override
  Future<void> clear() async => records.clear();
}

class _Intelligence implements MealIntelligence {
  _Intelligence({this.cloud = false});
  final bool cloud;
  int recognitionCalls = 0;
  int analysisCalls = 0;
  bool failRecognition = false;
  bool failAnalysis = false;
  Completer<MealRecognition>? pendingRecognition;
  Completer<MealAnalysis>? pendingAnalysis;
  MealDraft? analyzedDraft;
  UserProfile? analyzedProfile;

  @override
  bool get isCloud => cloud;
  @override
  bool get supportsImages => cloud;

  @override
  Future<MealRecognition> recognize(MealPhoto photo) async {
    recognitionCalls++;
    if (failRecognition) throw const MealServiceException('Chưa kết nối được.');
    return pendingRecognition?.future ?? _recognition();
  }

  @override
  Future<MealAnalysis> analyze(MealDraft draft, UserProfile profile) async {
    analysisCalls++;
    analyzedDraft = draft;
    analyzedProfile = profile;
    if (failAnalysis) throw const MealServiceException('Chưa kết nối được.');
    return pendingAnalysis?.future ?? _analysis();
  }
}

class _Picker implements MealPhotoPicker {
  MealPhoto? next = _photo();
  Object? error;
  @override
  Future<MealPhoto?> pick(MealPhotoSource source) async {
    if (error != null) throw error!;
    return next;
  }
}

class _RecoveringPicker extends DeviceMealPhotoPicker {
  _RecoveringPicker() : super(preferences: _RecoveryPreferences());

  int recoveryCalls = 0;

  @override
  Future<MealPhoto?> recoverLostPhoto() async {
    recoveryCalls++;
    return _photo();
  }

  @override
  Future<void> discardPendingPhoto() async {}
}

class _RecoveryPreferences implements SharedPreferencesAsync {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repository repository;
  late _Intelligence intelligence;
  late _Picker picker;
  late MealViewModel vm;
  var nextId = 0;

  MealViewModel createVm({bool cloud = false}) {
    repository = _Repository();
    intelligence = _Intelligence(cloud: cloud);
    picker = _Picker();
    return MealViewModel(
      repository: repository,
      intelligence: intelligence,
      photoPicker: picker,
      profile: () => _profile,
      now: () => _now,
      idFactory: () => 'meal-${nextId++}',
    );
  }

  Future<void> readyForAnalysis() async {
    vm.startNew();
    vm.updateName('Đậu hũ áp chảo');
    vm.addIngredient(const MealIngredient(name: 'Đậu hũ', amount: '1 miếng'));
    await vm.reviewIngredients();
    vm.setConfirmed(true);
    if (vm.isCloud) vm.setConsent(true);
  }

  setUp(() {
    nextId = 0;
    vm = createVm();
  });
  tearDown(() => vm.dispose());

  test('manual meal requires ingredients and explicit confirmation before analysis', () async {
    vm.startNew();
    vm.updateName('Món của tôi');
    await vm.reviewIngredients();
    await vm.analyze();
    expect(intelligence.analysisCalls, 0);
    expect(vm.errors.keys, containsAll(['ingredients', 'confirmed']));
    vm.addIngredient(const MealIngredient(name: 'Đậu hũ'));
    await vm.analyze();
    expect(intelligence.analysisCalls, 0);
    vm.setConfirmed(true);
    await vm.analyze();
    expect(vm.stage, MealStage.result);
    expect(intelligence.analyzedDraft!.ingredients.single.name, 'Đậu hũ');
    expect(intelligence.analyzedProfile, same(_profile));
  });

  test('editing a confirmed ingredient invalidates confirmation and prior analysis', () async {
    await readyForAnalysis();
    await vm.analyze();
    expect(vm.analysis, isNotNull);
    vm.editDraft();
    expect(vm.analysis, isNull);
    expect(vm.confirmed, isFalse);
    await vm.reviewIngredients();
    vm.setConfirmed(true);
    vm.updateIngredient(0, const MealIngredient(name: 'Rau xanh'));
    expect(vm.confirmed, isFalse);
    await vm.analyze();
    expect(intelligence.analysisCalls, 1);
    expect(vm.errors, contains('confirmed'));
  });

  test(
    'image upload and cloud analysis each enforce consent and confirmation',
    () async {
      vm.dispose();
      vm = createVm(cloud: true);
      vm.startNew();
      await vm.pickPhoto(MealPhotoSource.camera);
      await vm.recognizePhoto();
      expect(intelligence.recognitionCalls, 0);
      expect(vm.errors, contains('consent'));
      vm.setConsent(true);
      await vm.recognizePhoto();
      expect(vm.stage, MealStage.confirm);
      expect(vm.confirmed, isFalse);
      await vm.analyze();
      expect(intelligence.analysisCalls, 0);
      vm.setConfirmed(true);
      vm.setConsent(false);
      await vm.analyze();
      expect(intelligence.analysisCalls, 0);
      vm.setConsent(true);
      await vm.analyze();
      expect(intelligence.analysisCalls, 1);
    },
  );

  test('OCR text does not silently become an ingredient and a supplied name survives recognition', () async {
    vm.dispose();
    vm = createVm(cloud: true);
    vm.startNew();
    vm.updateName('Bữa ăn do tôi đặt tên');
    await vm.pickPhoto(MealPhotoSource.gallery);
    vm.setConsent(true);
    await vm.recognizePhoto();
    expect(vm.draft.name, 'Bữa ăn do tôi đặt tên');
    expect(vm.draft.ingredients.map((item) => item.name), ['Đậu hũ']);
    expect(vm.recognition!.ocrText, contains('nước tương'));
    expect(vm.confirmed, isFalse);
  });

  test(
    'photo cancellation and picker error preserve the existing meal draft',
    () async {
      vm.startNew();
      vm.updateName('Canh rau');
      vm.updateNotes('Ít nước dùng');
      await vm.pickPhoto(MealPhotoSource.gallery);
      final original = vm.photo;
      picker.next = null;
      await vm.pickPhoto(MealPhotoSource.camera);
      expect(vm.photo, same(original));
      picker.error = const MealServiceException('Quyền camera chưa được cấp.');
      await vm.pickPhoto(MealPhotoSource.camera);
      expect(vm.draft.name, 'Canh rau');
      expect(vm.draft.notes, 'Ít nước dùng');
      expect(vm.photo, same(original));
      expect(vm.errorMessage, contains('camera'));
    },
  );

  test(
    'recognition failure retains photo and draft and retry succeeds',
    () async {
      vm.dispose();
      vm = createVm(cloud: true);
      vm.startNew();
      vm.updateName('Bữa trưa của tôi');
      await vm.pickPhoto(MealPhotoSource.camera);
      vm.setConsent(true);
      intelligence.failRecognition = true;
      await vm.recognizePhoto();
      expect(vm.stage, MealStage.error);
      expect(vm.photo, isNotNull);
      expect(vm.draft.name, 'Bữa trưa của tôi');
      intelligence.failRecognition = false;
      await vm.retry();
      expect(vm.stage, MealStage.confirm);
      expect(intelligence.recognitionCalls, 2);
    },
  );

  test(
    'analysis failure preserves confirmed draft and retry uses the same ID',
    () async {
      await readyForAnalysis();
      final id = vm.draft.id;
      intelligence.failAnalysis = true;
      await vm.analyze();
      expect(vm.stage, MealStage.error);
      expect(vm.confirmed, isTrue);
      expect(vm.draft.ingredients.single.name, 'Đậu hũ');
      intelligence.failAnalysis = false;
      await vm.retry();
      expect(vm.stage, MealStage.result);
      expect(intelligence.analyzedDraft!.id, id);
    },
  );

  test('cancelled recognition cannot replace a new draft', () async {
    vm.dispose();
    vm = createVm(cloud: true);
    vm.startNew();
    await vm.pickPhoto(MealPhotoSource.gallery);
    vm.setConsent(true);
    intelligence.pendingRecognition = Completer<MealRecognition>();
    final pending = vm.recognizePhoto();
    expect(vm.stage, MealStage.recognizing);
    vm.startNew();
    vm.updateName('Món khác');
    intelligence.pendingRecognition!.complete(_recognition());
    await pending;
    expect(vm.stage, MealStage.entry);
    expect(vm.draft.name, 'Món khác');
    expect(vm.draft.ingredients, isEmpty);
    expect(vm.recognition, isNull);
  });

  test('editing during analysis ignores its late result', () async {
    await readyForAnalysis();
    intelligence.pendingAnalysis = Completer<MealAnalysis>();
    final pending = vm.analyze();
    expect(vm.stage, MealStage.analyzing);
    vm.editDraft();
    vm.updateName('Đã sửa món');
    intelligence.pendingAnalysis!.complete(_analysis());
    await pending;
    expect(vm.stage, MealStage.entry);
    expect(vm.draft.name, 'Đã sửa món');
    expect(vm.analysis, isNull);
  });

  test(
    'duplicate save and navigation are blocked until the same record is saved',
    () async {
      await readyForAnalysis();
      await vm.analyze();
      final id = vm.draft.id;
      repository.pendingSave = Completer<void>();
      final saving = vm.save();
      expect(vm.isSaving, isTrue);
      await vm.save();
      vm.startNew();
      vm.showHome();
      expect(vm.draft.id, id);
      expect(vm.stage, MealStage.result);
      expect(repository.saves, 1);
      repository.pendingSave!.complete();
      await saving;
      expect(vm.stage, MealStage.journal);
      expect(vm.records.single.id, id);
      expect(vm.todayCount, 1);
      expect(vm.isSaving, isFalse);
    },
  );

  test(
    'failed save retains result and retry saves exactly one entry',
    () async {
      await readyForAnalysis();
      await vm.analyze();
      final result = vm.analysis;
      final id = vm.draft.id;
      repository.failSave = true;
      await vm.save();
      expect(vm.stage, MealStage.result);
      expect(vm.analysis, same(result));
      expect(vm.draft.id, id);
      expect(vm.errorMessage, isNotNull);
      expect(vm.records, isEmpty);
      repository.failSave = false;
      await vm.retry();
      expect(repository.records.single.id, id);
      expect(vm.records.single.id, id);
      expect(vm.stage, MealStage.journal);
    },
  );

  test('a late journal load cannot erase a meal just saved', () async {
    repository.pendingLoad = Completer<List<MealRecord>>();
    final loading = vm.initialize();
    await readyForAnalysis();
    await vm.analyze();
    await vm.save();
    repository.pendingLoad!.complete([]);
    await loading;
    expect(vm.records, hasLength(1));
    expect(vm.todayCount, 1);
  });

  test(
    'signing out during initialization cannot recover a previous session photo',
    () async {
      vm.dispose();
      final recoveringPicker = _RecoveringPicker();
      repository = _Repository()..pendingLoad = Completer<List<MealRecord>>();
      vm = MealViewModel(
        repository: repository,
        intelligence: _Intelligence(),
        photoPicker: recoveringPicker,
        profile: () => _profile,
        now: () => _now,
        idFactory: () => 'recovery-meal',
      );
      final initializing = vm.initialize();
      await vm.clearPreviewSession();
      repository.pendingLoad!.complete([]);
      await initializing;
      expect(vm.stage, MealStage.home);
      expect(vm.photo, isNull);
      expect(recoveringPicker.recoveryCalls, 0);
    },
  );

  test(
    'journal date groups UTC instants by their local calendar day',
    () async {
      final instant = DateTime.utc(2026, 11, 2, 23, 30);
      final draft = MealDraft(
        id: 'saved',
        name: 'Đậu',
        mealType: MealType.dinner,
        eatenAt: instant,
        ingredients: const [MealIngredient(name: 'Đậu')],
      );
      repository.records.add(
        MealRecord(
          id: 'saved',
          draft: draft,
          analysis: _analysis(),
          savedAt: _now,
        ),
      );
      await vm.openJournal();
      final local = instant.toLocal();
      vm.selectJournalDate(DateTime(local.year, local.month, local.day));
      expect(vm.recordsForDate.single.id, 'saved');
      vm.selectJournalDate(DateTime(local.year, local.month, local.day + 1));
      expect(vm.recordsForDate, isEmpty);
    },
  );

  test('journal read failure is visible and retry recovers without invented records', () async {
    repository.failLoad = true;
    await vm.openJournal();
    expect(vm.journalError, isNotNull);
    expect(vm.records, isEmpty);
    repository.failLoad = false;
    await vm.retry();
    expect(vm.journalError, isNull);
    expect(vm.isLoadingJournal, isFalse);
  });

  test('disposed VM drops pending analysis and private state', () async {
    await readyForAnalysis();
    intelligence.pendingAnalysis = Completer<MealAnalysis>();
    final pending = vm.analyze();
    vm.dispose();
    intelligence.pendingAnalysis!.complete(_analysis());
    await pending;
    expect(vm.analysis, isNull);
    expect(vm.photo, isNull);
    expect(vm.records, isEmpty);
    // Avoid disposing the same ChangeNotifier twice in tearDown.
    vm = createVm();
  });
}
