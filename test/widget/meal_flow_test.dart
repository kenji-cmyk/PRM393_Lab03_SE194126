import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/meal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/screens/meal_flow_screen.dart';
import 'package:vetalife/services/meal_intelligence.dart';
import 'package:vetalife/services/meal_photo_picker.dart';
import 'package:vetalife/services/meal_repository.dart';
import 'package:vetalife/theme/app_theme.dart';
import 'package:vetalife/viewmodels/meal_view_model.dart';

class _Repository implements MealRepository {
  final records = <String, MealRecord>{};
  var saveCalls = 0;

  @override
  Future<List<MealRecord>> load() async => records.values.toList();

  @override
  Future<void> save(MealRecord record) async {
    saveCalls++;
    records[record.id] = record;
  }

  @override
  Future<void> clear() async => records.clear();
}

class _Intelligence implements MealIntelligence {
  _Intelligence({this.isCloud = true});

  @override
  final bool isCloud;
  @override
  bool get supportsImages => isCloud;
  int analyzeCalls = 0;
  int recognizeCalls = 0;
  bool failAnalysis = false;
  MealDraft? analyzedDraft;
  Completer<MealRecognition>? recognitionGate;

  @override
  Future<MealRecognition> recognize(MealPhoto photo) async {
    recognizeCalls++;
    if (recognitionGate != null) return recognitionGate!.future;
    return _recognition();
  }

  @override
  Future<MealAnalysis> analyze(MealDraft draft, UserProfile profile) async {
    analyzeCalls++;
    analyzedDraft = draft;
    if (failAnalysis) {
      throw const MealServiceException('Kết nối tạm gián đoạn. Hãy thử lại.');
    }
    return MealAnalysis(
      title: 'Gợi ý cho bữa ăn của bạn',
      summary: 'Dựa trên các thành phần đã xác nhận.',
      highlights: ['Bạn đã ghi rõ thành phần món ăn.'],
      improvements: ['Đối chiếu nội dung nguồn trước khi thay đổi thói quen.'],
      profileNote: 'Mục tiêu của bạn được dùng để trình bày gợi ý.',
      limitations: ['Không xác định được lượng dầu từ ảnh.'],
      references: const [
        BookReference(
          id: 'test-beans',
          chapterId: 'p2-dd01',
          title: 'Đậu',
          printedPage: 373,
          pdfPage: 375,
          summary: 'Mục tham khảo thử nghiệm cho tương tác giao diện.',
        ),
      ],
      healthConnections: [
        HealthConnection(
          topic: 'Chủ đề trong sách',
          explanation: 'Liên hệ được gắn với nguồn được cung cấp.',
          referenceIds: ['test-beans'],
        ),
      ],
      mode: isCloud ? 'gemini' : 'localBook',
    );
  }
}

MealRecognition _recognition() => MealRecognition(
  mealName: 'Đậu hũ cùng rau',
  ingredients: const [MealIngredient(name: 'đậu hũ')],
  ocrText: 'Thành phần trên nhãn',
  warnings: ['Hãy kiểm tra lại thành phần nhận diện.'],
);

class _Picker implements MealPhotoPicker {
  bool cancel = false;

  @override
  Future<MealPhoto?> pick(MealPhotoSource source) async {
    if (cancel) return null;
    return MealPhoto(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jWZkAAAAASUVORK5CYII=',
      ),
      mimeType: 'image/png',
      fileName: 'test-meal.png',
    );
  }
}

Future<MealViewModel> _pumpMeal(
  WidgetTester tester, {
  required _Repository repository,
  required _Intelligence intelligence,
  _Picker? picker,
  double width = 360,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final now = DateTime.now();
  final vm = MealViewModel(
    repository: repository,
    intelligence: intelligence,
    photoPicker: picker ?? _Picker(),
    profile: () => UserProfile(
      displayName: 'Nguyễn Ánh',
      birthDate: DateTime(2000, 2, 29),
      weightKg: 62.5,
      heightCm: 170.5,
      goal: HabitGoal.addVegetables,
    ),
    now: () => now,
    idFactory: () => 'meal-widget-test',
  );
  addTearDown(vm.dispose);
  await vm.initialize();
  vm.startNew();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: vm,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: MealFlowScreen(onHome: vm.showHome),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return vm;
}

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final field = _field(key);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _manualConfirmation(WidgetTester tester) async {
  await _enter(tester, 'meal-name', 'Đậu hũ áp chảo');
  await _enter(tester, 'meal-notes', 'Dùng ít nước chấm');
  tester.testTextInput.hide();
  await _tap(tester, find.text('Tiếp tục xác nhận'));
  await _tap(tester, find.byKey(const ValueKey('add-meal-ingredient')));
  await _enter(tester, 'ingredient-name-0', 'đậu hũ');
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [360.0, 412.0]) {
    testWidgets('confirmed meal is analyzed and saved at $width dp', (
      tester,
    ) async {
      final repository = _Repository();
      final intelligence = _Intelligence();
      final vm = await _pumpMeal(
        tester,
        repository: repository,
        intelligence: intelligence,
        width: width,
      );
      await _manualConfirmation(tester);
      final analyzeButton = find.widgetWithText(
        FilledButton,
        'Phân tích bữa ăn',
      );
      expect(tester.widget<FilledButton>(analyzeButton).onPressed, isNull);
      expect(intelligence.analyzeCalls, 0);

      await _tap(tester, find.byKey(const ValueKey('meal-confirmed')));
      expect(tester.widget<FilledButton>(analyzeButton).onPressed, isNull);
      await _tap(tester, find.byKey(const ValueKey('meal-cloud-consent')));
      await _tap(tester, analyzeButton);
      expect(intelligence.analyzeCalls, 1);
      expect(intelligence.analyzedDraft!.ingredients.single.name, 'đậu hũ');
      expect(find.text('Gợi ý cho bữa ăn của bạn'), findsOneWidget);
      await _tap(tester, find.text('Lưu vào nhật ký'));
      expect(vm.stage, MealStage.journal);
      expect(repository.saveCalls, 1);
      expect(repository.records.values.single.draft.notes, 'Dùng ít nước chấm');
      expect(find.text('1 bữa ăn đã ghi hôm nay'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _tap(tester, find.textContaining('Đậu hũ áp chảo').first);
      expect(vm.viewingSaved, isTrue);
      await _tap(tester, find.text('Chỉnh sửa thông tin'));
      expect(vm.stage, MealStage.entry);
      expect(vm.draft.id, 'meal-widget-test');
      await _tap(tester, find.text('Tiếp tục xác nhận'));
      expect(vm.confirmed, isFalse);
      await _tap(tester, find.byKey(const ValueKey('meal-confirmed')));
      await _tap(tester, find.byKey(const ValueKey('meal-cloud-consent')));
      await _tap(tester, find.text('Phân tích bữa ăn'));
      await _tap(tester, find.text('Lưu vào nhật ký'));
      expect(repository.saveCalls, 2);
      expect(repository.records, hasLength(1));
      expect(find.text('1 bữa ăn đã ghi hôm nay'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'recognition is provisional and OCR is separate from food edits',
    (tester) async {
      final intelligence = _Intelligence();
      final vm = await _pumpMeal(
        tester,
        repository: _Repository(),
        intelligence: intelligence,
      );
      await _tap(tester, find.text('Chụp ảnh'));
      await _tap(tester, find.byKey(const ValueKey('meal-cloud-consent')));
      await _tap(tester, find.text('Nhận diện món từ ảnh'));
      expect(vm.stage, MealStage.confirm);
      expect(vm.confirmed, isFalse);
      expect(intelligence.recognizeCalls, 1);
      expect(intelligence.analyzeCalls, 0);
      await _tap(tester, find.text('Chữ đọc từ ảnh (OCR)'));
      expect(find.text('Thành phần trên nhãn'), findsOneWidget);
      await _enter(tester, 'ingredient-name-0', 'cá');
      expect(vm.draft.ingredients.single.name, 'cá');
      expect(intelligence.analyzeCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('analysis failure keeps the draft and retries the same meal', (
    tester,
  ) async {
    final intelligence = _Intelligence()..failAnalysis = true;
    final vm = await _pumpMeal(
      tester,
      repository: _Repository(),
      intelligence: intelligence,
    );
    await _manualConfirmation(tester);
    await _tap(tester, find.byKey(const ValueKey('meal-confirmed')));
    await _tap(tester, find.byKey(const ValueKey('meal-cloud-consent')));
    await _tap(tester, find.text('Phân tích bữa ăn'));
    expect(vm.stage, MealStage.error);
    expect(vm.draft.name, 'Đậu hũ áp chảo');
    expect(vm.draft.notes, 'Dùng ít nước chấm');
    expect(find.text('Chưa thể tải gợi ý'), findsOneWidget);
    intelligence.failAnalysis = false;
    await _tap(tester, find.text('Thử lại'));
    expect(vm.stage, MealStage.result);
    expect(intelligence.analyzeCalls, 2);
    expect(intelligence.analyzedDraft!.id, 'meal-widget-test');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'camera cancellation preserves input at large text with keyboard',
    (tester) async {
      final picker = _Picker()..cancel = true;
      final vm = await _pumpMeal(
        tester,
        repository: _Repository(),
        intelligence: _Intelligence(),
        picker: picker,
        textScale: 1.5,
      );
      await _enter(tester, 'meal-name', 'Bữa trưa tự nấu');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await _tap(tester, find.text('Chụp ảnh'));
      expect(vm.draft.name, 'Bữa trưa tự nấu');
      expect(vm.photo, isNull);
      tester.testTextInput.hide();
      await _tap(tester, find.text('Tiếp tục xác nhận'));
      expect(vm.stage, MealStage.confirm);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('journal empty day shows actual state and preview is labelled', (
    tester,
  ) async {
    final vm = await _pumpMeal(
      tester,
      repository: _Repository(),
      intelligence: _Intelligence(isCloud: false),
    );
    await vm.openJournal();
    await tester.pumpAndSettle();
    vm.selectJournalDate(
      DateTime(
        vm.journalDate.year,
        vm.journalDate.month,
        vm.journalDate.day - 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có bữa ăn nào'), findsOneWidget);
    expect(find.text('Ngày chưa ghi bữa'), findsOneWidget);
    expect(
      find.textContaining('Đối chiếu sách và lưu nhật ký'),
      findsOneWidget,
    );
    expect(find.text('Đậu hũ áp chảo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
