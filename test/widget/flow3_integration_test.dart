import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/meal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/screens/flow_screen.dart';
import 'package:vetalife/services/book_meal_intelligence.dart';
import 'package:vetalife/services/local_lesson_progress_repository.dart';
import 'package:vetalife/services/local_meal_repository.dart';
import 'package:vetalife/services/meal_photo_picker.dart';
import 'package:vetalife/services/onboarding_repository.dart';
import 'package:vetalife/theme/app_theme.dart';
import 'package:vetalife/viewmodels/learning_view_model.dart';
import 'package:vetalife/viewmodels/meal_view_model.dart';
import 'package:vetalife/viewmodels/onboarding_view_model.dart';

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

class _Profile implements OnboardingRepository {
  @override
  Future<UserProfile?> load() async => UserProfile(
    displayName: 'Người dùng thử',
    birthDate: DateTime(2000),
    weightKg: 60,
    heightCm: 165,
    goal: HabitGoal.readDaily,
  );
  @override
  Future<void> save(UserProfile profile) async {}
  @override
  Future<void> clear() async {}
}

class _Picker implements MealPhotoPicker {
  @override
  Future<MealPhoto?> pick(MealPhotoSource source) async => null;
}

void main() {
  testWidgets(
    'home, learning, reader and journal share one session and persist read IDs',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferences = _Preferences();
      final onboarding = OnboardingViewModel(_Profile());
      final meals = MealViewModel(
        repository: LocalMealRepository(preferences: preferences),
        intelligence: BookMealIntelligence(),
        photoPicker: _Picker(),
        profile: () => onboarding.profile,
      );
      final learning = LearningViewModel(
        repository: LocalLessonProgressRepository(preferences: preferences),
      );
      addTearDown(onboarding.dispose);
      addTearDown(meals.dispose);
      addTearDown(learning.dispose);
      await onboarding.init();
      await meals.initialize();
      await learning.initialize();
      expect(learning.catalog?.coreCount, 27);
      expect(learning.catalog?.lessons.length, 30);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: onboarding),
            ChangeNotifierProvider.value(value: meals),
            ChangeNotifierProvider.value(value: learning),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: FlowScreen(isPreview: true, onSignOut: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiến trình'));
      await tester.pumpAndSettle();
      expect(learning.stage, LearningStage.progress);
      await tester.ensureVisible(
        find.byKey(const ValueKey('learning-open-catalogue')),
      );
      await tester.tap(find.byKey(const ValueKey('learning-open-catalogue')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phần 2'));
      await tester.pumpAndSettle();

      Future<void> read(String id) async {
        final card = find.byKey(ValueKey('learning-lesson-$id'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(learning.selectedLesson?.id, id);
        expect(learning.isRead(id), isFalse);
        final mark = find.byKey(const ValueKey('learning-mark-read'));
        await tester.ensureVisible(mark);
        await tester.tap(mark);
        await tester.pumpAndSettle();
        expect(learning.isRead(id), isTrue);
        expect(find.text('Đã đọc'), findsOneWidget);
        await tester.ensureVisible(find.text('Quay về mục lục'));
        await tester.tap(find.text('Quay về mục lục'));
        await tester.pumpAndSettle();
        expect(learning.selectedPartId, 'part-2');
      }

      await read('p2-introduction');
      expect(learning.completedCoreCount, 0);
      await read('p2-dd01');
      expect(learning.completedCoreCount, 1);
      await tester.tap(find.text('Nhật ký'));
      await tester.pumpAndSettle();
      expect(meals.stage, MealStage.journal);
      expect(learning.stage, LearningStage.home);
      expect(find.text('Nhật ký bữa ăn'), findsOneWidget);
      await tester.tap(find.text('Học'));
      await tester.pumpAndSettle();
      expect(meals.stage, MealStage.home);
      expect(learning.stage, LearningStage.catalog);
      expect(learning.selectedPartId, 'part-2');
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
      expect(find.text('VetaLife'), findsOneWidget);

      final reloaded = LearningViewModel(
        repository: LocalLessonProgressRepository(preferences: preferences),
      );
      addTearDown(reloaded.dispose);
      await reloaded.initialize();
      expect(reloaded.completedCoreCount, 1);
      expect(reloaded.readProgress.map((read) => read.lessonId).toSet(), {
        'p2-introduction',
        'p2-dd01',
      });
      expect(tester.takeException(), isNull);
    },
  );
}
