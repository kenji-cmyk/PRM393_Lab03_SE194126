import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetalife/app.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/meal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/screens/cloud_settings_screen.dart';
import 'package:vetalife/screens/flow_screen.dart';
import 'package:vetalife/screens/report_screen.dart';
import 'package:vetalife/services/app_settings.dart';
import 'package:vetalife/services/book_meal_intelligence.dart';
import 'package:vetalife/services/local_lesson_progress_repository.dart';
import 'package:vetalife/services/local_meal_repository.dart';
import 'package:vetalife/services/local_onboarding_repository.dart';
import 'package:vetalife/services/meal_photo_picker.dart';
import 'package:vetalife/theme/app_theme.dart';
import 'package:vetalife/viewmodels/learning_view_model.dart';
import 'package:vetalife/viewmodels/meal_view_model.dart';
import 'package:vetalife/viewmodels/onboarding_view_model.dart';
import 'package:vetalife/viewmodels/report_view_model.dart';

class _Preferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Picker implements MealPhotoPicker {
  @override
  Future<MealPhoto?> pick(MealPhotoSource source) async => null;
}

class _SettingsSource implements AppSettingsSource {
  Map<String, bool> values = Map.of(AppSettings.defaults);
  bool fail = false;
  @override
  Future<Map<String, bool>> fetch() async {
    if (fail) throw StateError('Unavailable');
    return values;
  }
}

_Preferences _savedPreferences() =>
    _Preferences()
      ..values[LocalOnboardingRepository.storageKey] = jsonEncode(
        UserProfile(
          displayName: 'Người dùng thử',
          birthDate: DateTime(2000),
          weightKg: 60,
          heightCm: 165,
          goal: HabitGoal.readDaily,
        ).toJson(),
      );

Future<void> _viewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _preview(WidgetTester tester) async {
  await _viewport(tester);
  await tester.pumpWidget(
    VetaLifeApp(key: UniqueKey(), previewPreferences: _savedPreferences()),
  );
  await tester.pumpAndSettle();
  final context = tester.element(find.byType(FlowScreen));
  final learning = context.read<LearningViewModel>();
  for (var attempt = 0; attempt < 30 && !learning.progressReady; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(learning.progressReady, isTrue, reason: learning.errorMessage);
}

Future<void> _menu(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Hồ sơ của bạn'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<ReportViewModel> _generateReport(WidgetTester tester) async {
  await _menu(tester, 'Xuất báo cáo PDF');
  final vm = tester.widget<ReportScreen>(find.byType(ReportScreen)).viewModel;
  expect(vm.canOpen, isFalse);
  // Font loading and PDF serialization use actual asynchronous IO. Keep that
  // work outside Flutter's fake clock, while triggering the real UI action.
  await tester.runAsync(() async {
    await tester.tap(find.text('Tạo PDF xem thử'));
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (vm.isBusy && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
  expect(vm.isBusy, isFalse);
  expect(vm.errorMessage, isNull);
  expect(vm.canOpen, isTrue);
  expect(vm.uploaded, isNull);
  expect(find.text('Đã tạo PDF xem thử. Chưa tải lên cloud.'), findsOneWidget);
  expect(find.text('Mở PDF'), findsOneWidget);
  return vm;
}

void main() {
  setUp(rootBundle.clear);

  testWidgets(
    'preview menu opens settings and creates a local report, then returns home',
    (tester) async {
      await _preview(tester);
      await _menu(tester, 'Cài đặt ứng dụng');
      expect(find.byType(CloudSettingsScreen), findsOneWidget);
      expect(
        find.text('Chế độ xem thử: dùng cấu hình mặc định.'),
        findsOneWidget,
      );
      expect(find.text('Đang mở'), findsNWidgets(2));
      expect(find.text('Tải lại cấu hình'), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Chào Người dùng thử'), findsOneWidget);
      await _generateReport(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Chào Người dùng thử'), findsOneWidget);
      expect(find.byType(ReportScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sign-out disposes generated personal PDF before another preview profile',
    (tester) async {
      await _preview(tester);
      final oldReport = await _generateReport(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _menu(tester, 'Đăng xuất');
      final context = tester.element(find.byType(FlowScreen));
      final onboarding = context.read<OnboardingViewModel>();
      expect(onboarding.stage, OnboardingStage.welcome);
      expect(oldReport.canOpen, isFalse);

      // Existing onboarding tests exercise the fields. Here the real provider's
      // save completes a second session to verify feature-tree ownership.
      onboarding.start();
      onboarding.updateDisplayName('Tài khoản mới');
      onboarding.updateBirthDate('01/01/2001');
      onboarding.updateWeight('61');
      onboarding.updateHeight('166');
      expect(onboarding.continueToGoals(), isTrue);
      await onboarding.save();
      await tester.pumpAndSettle();
      expect(find.text('Chào Tài khoản mới'), findsOneWidget);
      await _menu(tester, 'Xuất báo cáo PDF');
      final newReport = tester
          .widget<ReportScreen>(find.byType(ReportScreen))
          .viewModel;
      expect(identical(oldReport, newReport), isFalse);
      expect(newReport.canOpen, isFalse);
      expect(newReport.uploaded, isNull);
      expect(find.text('Mở PDF'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fetched settings visibly disable and restore learning and report actions without rebuilding app',
    (tester) async {
      await _viewport(tester);
      final preferences = _savedPreferences();
      final source = _SettingsSource();
      final settings = AppSettings(source: source);
      final onboarding = OnboardingViewModel(
        LocalOnboardingRepository(preferences: preferences),
      );
      final meals = MealViewModel(
        repository: LocalMealRepository(preferences: preferences),
        intelligence: BookMealIntelligence(),
        photoPicker: _Picker(),
        profile: () => onboarding.profile,
      );
      final learning = LearningViewModel(
        repository: LocalLessonProgressRepository(preferences: preferences),
      );
      addTearDown(settings.dispose);
      addTearDown(onboarding.dispose);
      addTearDown(meals.dispose);
      addTearDown(learning.dispose);
      await onboarding.init();
      await meals.initialize();
      await learning.initialize();
      await settings.initialize();
      var reportOpens = 0;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: onboarding),
            ChangeNotifierProvider.value(value: meals),
            ChangeNotifierProvider.value(value: learning),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: FlowScreen(
              isPreview: true,
              onSignOut: () {},
              onReport: () => reportOpens++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      source.values = {
        'learning_enabled': false,
        'report_export_enabled': false,
      };
      await settings.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Học (tạm đóng)'), findsOneWidget);
      await tester.tap(find.text('Học (tạm đóng)'));
      await tester.pumpAndSettle();
      expect(learning.stage, LearningStage.home);
      await tester.tap(find.byTooltip('Hồ sơ của bạn'));
      await tester.pumpAndSettle();
      final disabled = find.widgetWithText(
        PopupMenuItem<String>,
        'Xuất báo cáo đang tạm đóng',
      );
      expect(tester.widget<PopupMenuItem<String>>(disabled).enabled, isFalse);
      await tester.tap(find.text('Xuất báo cáo đang tạm đóng'));
      await tester.pumpAndSettle();
      expect(reportOpens, 0);
      await tester.tapAt(const Offset(20, 700));
      await tester.pumpAndSettle();

      source.fail = true;
      await settings.refresh();
      expect(settings.reportExportEnabled, isFalse);
      source.fail = false;
      source.values = Map.of(AppSettings.defaults);
      await settings.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Học'), findsOneWidget);
      await _menu(tester, 'Xuất báo cáo PDF');
      expect(reportOpens, 1);
      await tester.tap(find.text('Học'));
      await tester.pumpAndSettle();
      expect(learning.stage, LearningStage.catalog);
      expect(tester.takeException(), isNull);
    },
  );
}
