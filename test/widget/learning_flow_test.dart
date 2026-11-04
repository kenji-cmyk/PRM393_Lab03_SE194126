import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vetalife/models/lesson.dart';
import 'package:vetalife/models/meal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/screens/learning_flow_screen.dart';
import 'package:vetalife/services/lesson_progress_repository.dart';
import 'package:vetalife/services/meal_intelligence.dart';
import 'package:vetalife/services/meal_photo_picker.dart';
import 'package:vetalife/services/meal_repository.dart';
import 'package:vetalife/theme/app_theme.dart';
import 'package:vetalife/viewmodels/learning_view_model.dart';
import 'package:vetalife/viewmodels/meal_view_model.dart';

final _now = DateTime(2026, 12, 2, 12);
late LessonCatalog _catalog;

class _ProgressRepository implements LessonProgressRepository {
  final progress = <String, LessonReadProgress>{};
  var saveCalls = 0;
  var loadFails = false;
  var saveFails = false;
  Completer<void>? pendingSave;

  @override
  Future<List<LessonReadProgress>> load() async {
    if (loadFails) throw StateError('Injected load failure');
    return progress.values.toList();
  }

  @override
  Future<void> save(LessonReadProgress value) async {
    saveCalls++;
    if (saveFails) throw StateError('Injected save failure');
    if (pendingSave != null) await pendingSave!.future;
    progress[value.lessonId] = value;
  }

  @override
  Future<void> clearPreview() async => progress.clear();
}

class _MealRepository implements MealRepository {
  _MealRepository(this.records);
  final List<MealRecord> records;
  @override
  Future<List<MealRecord>> load() async => records;
  @override
  Future<void> save(MealRecord record) async {}
  @override
  Future<void> clear() async => records.clear();
}

class _Intelligence implements MealIntelligence {
  @override
  bool get isCloud => false;
  @override
  bool get supportsImages => false;
  @override
  Future<MealRecognition> recognize(MealPhoto photo) async =>
      throw UnimplementedError();
  @override
  Future<MealAnalysis> analyze(MealDraft draft, UserProfile profile) async =>
      throw UnimplementedError();
}

class _Picker implements MealPhotoPicker {
  @override
  Future<MealPhoto?> pick(MealPhotoSource source) async => null;
}

MealRecord _meal(String id, DateTime eatenAt) => MealRecord(
  id: id,
  draft: MealDraft(
    id: id,
    name: 'Bữa ăn giả phục vụ kiểm thử',
    mealType: MealType.lunch,
    eatenAt: eatenAt,
    ingredients: const [MealIngredient(name: 'Đậu')],
  ),
  analysis: MealAnalysis(
    title: 'Kết quả giả phục vụ kiểm thử',
    summary: 'Không phải nhận định dinh dưỡng.',
    highlights: [],
    improvements: [],
    profileNote: '',
    limitations: [],
    references: [],
    healthConnections: [],
    mode: 'localBook',
  ),
  savedAt: eatenAt,
);

Future<LearningViewModel> _pump(
  WidgetTester tester, {
  required _ProgressRepository repository,
  double width = 360,
  double textScale = 1,
  double keyboardInset = 0,
  bool progressScreen = false,
  List<MealRecord>? mealRecords,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final vm = LearningViewModel(
    repository: repository,
    loadCatalog: () async => _catalog,
    now: () => _now,
  );
  addTearDown(vm.dispose);
  await vm.initialize();
  if (progressScreen) {
    vm.showProgress();
  } else {
    vm.showCatalog();
  }
  MealViewModel? meals;
  if (mealRecords != null) {
    meals = MealViewModel(
      repository: _MealRepository(mealRecords),
      intelligence: _Intelligence(),
      photoPicker: _Picker(),
      profile: () => null,
      now: () => _now,
    );
    addTearDown(meals.dispose);
    await meals.initialize();
  }
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: vm),
        if (meals != null) ChangeNotifierProvider.value(value: meals),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: child!,
        ),
        home: LearningFlowScreen(
          onHome: vm.showHome,
          onJournal: () {},
          now: () => _now,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return vm;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _lesson(String id) => find.byKey(ValueKey('learning-lesson-$id'));
Finder get _readButton => find.byKey(const ValueKey('learning-mark-read'));

void main() {
  setUpAll(() async {
    final outline = jsonDecode(
      await File('assets/content/lesson-catalog.json').readAsString(),
    ) as Map<String, dynamic>;
    final bodies = <Map<String, dynamic>>[];
    void visit(Map<String, dynamic> unit) {
      bodies.add({
        'lessonId': unit['id'],
        'summary': 'Tóm tắt giả để kiểm tra cách hiển thị bài ${unit['id']}.',
        'sections': [
          {
            'heading': 'Nội dung kiểm thử',
            'paragraphs': [
              'Đoạn văn giả cho kiểm thử điều hướng và lưu tiến độ.',
            ],
          },
        ],
        'reflection': 'Bạn muốn tìm hiểu điều gì sau khi đọc?',
        'sourcePages': [
          {'printedPage': unit['printedPage'], 'pdfPage': unit['pdfPage']},
        ],
      });
      for (final child in unit['children'] as List<dynamic>? ?? []) {
        visit(child as Map<String, dynamic>);
      }
    }

    for (final part in outline['parts'] as List<dynamic>) {
      for (final unit in part['units'] as List<dynamic>) {
        visit(unit as Map<String, dynamic>);
      }
    }
    _catalog = LessonCatalog.fromJson(outline, {
      'schemaVersion': 1,
      'lessons': bodies,
    });
  });

  test(
    'weekly counts use saved IDs and local dates across a month boundary',
    () {
      final monday = DateTime(2026, 11, 30, 12);
      final summary = LearningWeekSummary.fromRecords([
        _meal('monday-one', monday),
        _meal('monday-two', monday),
        _meal('monday-one', monday),
        _meal('wednesday', _now),
        _meal('previous-sunday', DateTime(2026, 11, 29, 12)),
        _meal('future-thursday', DateTime(2026, 12, 3, 12)),
      ], _now);
      expect(summary.start, DateTime(2026, 11, 30));
      expect(summary.end, DateTime(2026, 12, 6));
      expect(summary.counts, [2, 0, 1, 0, 0, 0, 0]);
      expect(summary.recordedDays, 2);
      expect(summary.textAlternative, contains('T2: 2 bữa'));
      expect(summary.textAlternative, contains('T5: 0 bữa'));
    },
  );

  for (final width in [360.0, 412.0]) {
    testWidgets('catalogue reader saves explicit progress at $width dp', (
      tester,
    ) async {
      final repository = _ProgressRepository();
      final vm = await _pump(tester, repository: repository, width: width);
      expect(find.text('Đã đọc 0/27 bài chính'), findsOneWidget);
      expect(repository.saveCalls, 0);
      await _tap(tester, find.text('Phần 2'));
      await _tap(tester, _lesson('p2-introduction'));
      expect(vm.selectedLesson?.id, 'p2-introduction');
      expect(repository.saveCalls, 0);
      await _tap(tester, _readButton);
      expect(vm.completedCoreCount, 0);
      expect(repository.saveCalls, 1);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Đã đọc'))
            .onPressed,
        isNull,
      );
      await _tap(tester, find.text('Quay về mục lục'));
      expect(vm.selectedPartId, 'part-2');
      await _tap(tester, _lesson('p2-dd01'));
      await _tap(tester, _readButton);
      expect(repository.saveCalls, 2);
      expect(vm.completedCoreCount, 1);
      await _tap(tester, find.text('Quay về mục lục'));
      expect(find.text('Đã đọc 1/27 bài chính'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final restored = LearningViewModel(
        repository: repository,
        loadCatalog: () async => _catalog,
      );
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.completedCoreCount, 1);
      expect(restored.isRead('p2-introduction'), isTrue);
    });
  }

  testWidgets(
    'failed progress save retains reader and retries without fake completion',
    (tester) async {
      final repository = _ProgressRepository()..saveFails = true;
      final vm = await _pump(tester, repository: repository);
      await _tap(tester, _lesson('p1-ch01'));
      await _tap(tester, _readButton);
      expect(vm.stage, LearningStage.detail);
      expect(vm.completedCoreCount, 0);
      expect(
        find.textContaining('Chưa lưu được trạng thái đã đọc'),
        findsOneWidget,
      );
      repository.saveFails = false;
      await _tap(tester, find.text('Thử lại'));
      expect(vm.completedCoreCount, 1);
      expect(repository.saveCalls, 2);
      expect(find.widgetWithText(FilledButton, 'Đã đọc'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'progress-load failure keeps book readable and retries before saving',
    (tester) async {
      final repository = _ProgressRepository()..loadFails = true;
      final vm = await _pump(tester, repository: repository);
      expect(find.text('Đã đọc 0/27 bài chính'), findsNothing);
      await _tap(tester, _lesson('p1-ch01'));
      expect(find.text('Nội dung kiểm thử'), findsOneWidget);
      await _tap(tester, _readButton);
      expect(repository.saveCalls, 0);
      repository.loadFails = false;
      await _tap(tester, find.text('Thử lại'));
      await _tap(tester, _readButton);
      expect(vm.isRead('p1-ch01'), isTrue);
      expect(repository.saveCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending read save blocks duplicate submission and system back', (
    tester,
  ) async {
    final repository = _ProgressRepository()..pendingSave = Completer<void>();
    final vm = await _pump(tester, repository: repository);
    await _tap(tester, _lesson('p1-ch01'));
    await tester.ensureVisible(_readButton);
    await tester.tap(_readButton);
    await tester.pump();
    expect(vm.isSaving, isTrue);
    expect(repository.saveCalls, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Đang lưu tiến độ…'),
          )
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(vm.stage, LearningStage.detail);
    expect(vm.completedCoreCount, 0);
    repository.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(vm.completedCoreCount, 1);
    expect(repository.saveCalls, 1);
  });

  testWidgets(
    'long chapter stays readable with enlarged text and keyboard inset',
    (tester) async {
      final repository = _ProgressRepository();
      final vm = await _pump(
        tester,
        repository: repository,
        textScale: 1.5,
        keyboardInset: 220,
      );
      await _tap(tester, _lesson('p1-ch15'));
      expect(vm.selectedLesson?.id, 'p1-ch15');
      expect(
        find.textContaining(
          'Để không chết vì các nguyên nhân do khám và điều trị',
        ),
        findsOneWidget,
      );
      await _tap(tester, _readButton);
      expect(vm.completedCoreCount, 1);
      await _tap(tester, find.text('Quay về mục lục'));
      expect(vm.selectedPartId, 'part-1');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'weekly bars, accessible text and day count use the same records',
    (tester) async {
      await _pump(
        tester,
        repository: _ProgressRepository(),
        progressScreen: true,
        mealRecords: [
          _meal('monday', DateTime(2026, 11, 30, 12)),
          _meal('wednesday', _now),
          _meal('future', DateTime(2026, 12, 3, 12)),
        ],
      );
      expect(find.text('2 trong 7 ngày'), findsOneWidget);
      expect(find.textContaining('T2: 1 bữa'), findsOneWidget);
      expect(find.textContaining('T5: 0 bữa'), findsOneWidget);
      final filled = tester.widget<Container>(
        find.byKey(const ValueKey('learning-day-bar-0')),
      );
      final empty = tester.widget<Container>(
        find.byKey(const ValueKey('learning-day-bar-3')),
      );
      expect((filled.decoration as BoxDecoration).color, AppTokens.primary);
      expect(
        (empty.decoration as BoxDecoration).color,
        AppTokens.primaryContainer,
      );
      expect(find.text('Đã đọc 0/27 bài chính'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
