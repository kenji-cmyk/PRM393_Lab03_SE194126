import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nep_lanh/models/habit_goal.dart';
import 'package:nep_lanh/models/user_profile.dart';
import 'package:nep_lanh/screens/flow_screen.dart';
import 'package:nep_lanh/services/onboarding_repository.dart';
import 'package:nep_lanh/theme/app_theme.dart';
import 'package:nep_lanh/viewmodels/onboarding_view_model.dart';

class _Repository implements OnboardingRepository {
  UserProfile? stored;
  bool failLoad = false;
  bool failSave = false;
  int saveCalls = 0;
  Completer<void>? saveGate;

  @override
  Future<UserProfile?> load() async {
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
  Future<void> clear() async => stored = null;
}

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final finder = _field(key);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

Future<void> _fillProfile(WidgetTester tester) async {
  await _enter(tester, 'profile_name', '  Nguyễn Ánh  ');
  await _enter(tester, 'profile_birth_date', '04/11/2000');
  await _enter(tester, 'profile_weight', '62,5');
  await _enter(tester, 'profile_height', '170.5');
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

Future<OnboardingViewModel> _pumpFlow(
  WidgetTester tester,
  _Repository repository, {
  double width = 360,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final vm = OnboardingViewModel(repository, now: () => DateTime(2026, 11, 3));
  addTearDown(vm.dispose);
  await vm.init();
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
        home: FlowScreen(onSignOut: () {}, isPreview: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return vm;
}

void main() {
  for (final width in [360.0, 412.0]) {
    testWidgets('flow 1 validates and saves the actual profile at $width dp', (
      tester,
    ) async {
      final repository = _Repository();
      final vm = await _pumpFlow(tester, repository, width: width);
      expect(find.text('Ăn xanh hơn,\nkhỏe từng ngày'), findsOneWidget);
      await _tap(tester, find.text('Thiết lập mục tiêu'));
      await _tap(tester, find.text('Tiếp tục'));
      expect(find.text('Vui lòng nhập họ và tên.'), findsOneWidget);
      expect(find.text('Vui lòng nhập ngày sinh.'), findsOneWidget);
      expect(find.text('Nhập cân nặng lớn hơn 0.'), findsOneWidget);
      expect(find.text('Nhập chiều cao lớn hơn 0.'), findsOneWidget);
      expect(repository.saveCalls, 0);

      await _fillProfile(tester);
      final ageField = tester.widget<TextField>(_field('profile_age'));
      expect(ageField.readOnly, isTrue);
      expect(ageField.controller!.text, '25');
      await _tap(tester, find.text('Tiếp tục'));
      await _tap(tester, find.byKey(const ValueKey('goal_readDaily')));
      await _tap(tester, find.text('Lưu mục tiêu'));

      expect(vm.stage, OnboardingStage.home);
      expect(find.text('Chào Nguyễn Ánh'), findsOneWidget);
      expect(find.text('Đọc 5 phút mỗi ngày'), findsOneWidget);
      expect(find.text('Chưa có bữa ăn nào được ghi lại'), findsOneWidget);
      expect(repository.saveCalls, 1);
      expect(repository.stored!.displayName, 'Nguyễn Ánh');
      expect(repository.stored!.birthDate, DateTime(2000, 11, 4));
      expect(repository.stored!.weightKg, 62.5);
      expect(repository.stored!.heightCm, 170.5);
      expect(repository.stored!.goal, HabitGoal.readDaily);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('back preserves fields and goal; failed saving can retry', (
    tester,
  ) async {
    final repository = _Repository()..failSave = true;
    final vm = await _pumpFlow(tester, repository);
    await _tap(tester, find.text('Thiết lập mục tiêu'));
    await _fillProfile(tester);
    await _tap(tester, find.text('Tiếp tục'));
    await _tap(tester, find.byKey(const ValueKey('goal_recordMeals')));
    await _tap(tester, find.byTooltip('Quay lại'));
    expect(
      tester.widget<TextField>(_field('profile_name')).controller!.text,
      '  Nguyễn Ánh  ',
    );
    expect(
      tester.widget<TextField>(_field('profile_weight')).controller!.text,
      '62,5',
    );
    await _tap(tester, find.text('Tiếp tục'));
    expect(find.text('✓ Ghi lại bữa ăn'), findsOneWidget);
    await _tap(tester, find.text('Lưu mục tiêu'));
    expect(vm.stage, OnboardingStage.goals);
    expect(
      find.text('Chưa lưu được hồ sơ. Thông tin vẫn được giữ, hãy thử lại.'),
      findsOneWidget,
    );
    expect(repository.stored, isNull);
    repository.failSave = false;
    await _tap(tester, find.text('Thử lưu lại'));
    expect(find.text('Chào Nguyễn Ánh'), findsOneWidget);
    expect(repository.stored!.goal, HabitGoal.recordMeals);
    expect(repository.saveCalls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in-flight save disables duplicate submission and back', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = _Repository()..saveGate = gate;
    final vm = await _pumpFlow(tester, repository);
    await _tap(tester, find.text('Thiết lập mục tiêu'));
    await _fillProfile(tester);
    await _tap(tester, find.text('Tiếp tục'));
    await tester.ensureVisible(find.text('Lưu mục tiêu'));
    await tester.tap(find.text('Lưu mục tiêu'));
    await tester.pump();
    expect(find.text('Đang lưu…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Đang lưu…'));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(vm.stage, OnboardingStage.goals);
    expect(repository.saveCalls, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Chào Nguyễn Ánh'), findsOneWidget);
    expect(repository.saveCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('load failure offers retry and restores saved home', (
    tester,
  ) async {
    final repository = _Repository()
      ..failLoad = true
      ..stored = UserProfile(
        displayName: 'Lê Mai',
        birthDate: DateTime(1999, 5, 4),
        weightKg: 55,
        heightCm: 165,
        goal: HabitGoal.addVegetables,
      );
    await _pumpFlow(tester, repository);
    expect(find.text('Chưa thể tải hồ sơ'), findsOneWidget);
    repository.failLoad = false;
    await _tap(tester, find.text('Thử lại'));
    expect(find.text('Chào Lê Mai'), findsOneWidget);
    expect(find.text('Thiết lập mục tiêu'), findsNothing);
    expect(repository.saveCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text and keyboard keep the profile action reachable', (
    tester,
  ) async {
    final repository = _Repository();
    await _pumpFlow(tester, repository, textScale: 1.5);
    await _tap(tester, find.text('Thiết lập mục tiêu'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await _fillProfile(tester);
    expect(tester.takeException(), isNull);
    await _tap(tester, find.text('Tiếp tục'));
    expect(find.text('Bạn muốn bắt đầu từ đâu?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar can be cancelled without changing birth date', (
    tester,
  ) async {
    final vm = await _pumpFlow(tester, _Repository());
    await _tap(tester, find.text('Thiết lập mục tiêu'));
    await _enter(tester, 'profile_birth_date', '04/11/2000');
    tester.testTextInput.hide();
    await _tap(tester, find.text('Chọn ngày sinh'));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await _tap(tester, find.text('Hủy'));
    expect(vm.birthDateText, '04/11/2000');
    expect(
      tester.widget<TextField>(_field('profile_birth_date')).controller!.text,
      '04/11/2000',
    );
    expect(tester.takeException(), isNull);
  });
}
