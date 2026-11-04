import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetalife/app.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/lesson.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/screens/flow_screen.dart';
import 'package:vetalife/services/local_lesson_progress_repository.dart';
import 'package:vetalife/services/local_meal_repository.dart';
import 'package:vetalife/services/local_onboarding_repository.dart';
import 'package:vetalife/viewmodels/learning_view_model.dart';
import 'package:vetalife/viewmodels/onboarding_view_model.dart';

class _DelayedPreferences implements SharedPreferencesAsync {
  _DelayedPreferences(this.blockedKey);
  final String blockedKey;
  final values = <String, String>{};
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async {
    if (key == blockedKey && !started.isCompleted) {
      started.complete();
      await release.future;
    }
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(rootBundle.clear);
  for (final key in [
    LocalMealRepository.storageKey,
    LocalOnboardingRepository.storageKey,
  ]) {
    testWidgets(
      'preview sign-out blocks lesson writes while $key is being cleared',
      (tester) async {
        final preferences = _DelayedPreferences(key);
        preferences.values[LocalOnboardingRepository.storageKey] = jsonEncode(
          UserProfile(
            displayName: 'Người dùng thử',
            birthDate: DateTime(2000),
            weightKg: 60,
            heightCm: 165,
            goal: HabitGoal.readDaily,
          ).toJson(),
        );
        preferences.values[LocalLessonProgressRepository.storageKey] =
            jsonEncode([
              LessonReadProgress(
                lessonId: 'p1-ch01',
                readAt: DateTime.utc(2026, 11, 4),
              ).toJson(),
            ]);
        await tester.pumpWidget(
          VetaLifeApp(key: UniqueKey(), previewPreferences: preferences),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(FlowScreen));
        final learning = context.read<LearningViewModel>();
        final onboarding = context.read<OnboardingViewModel>();
        // Await initialization through the real application composition.
        for (var pump = 0; pump < 20 && !learning.progressReady; pump++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(learning.progressReady, isTrue, reason: learning.errorMessage);
        expect(learning.readProgress.length, 1);
        await tester.tap(find.byTooltip('Hồ sơ của bạn'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đăng xuất'));
        for (
          var pump = 0;
          pump < 20 && !preferences.started.isCompleted;
          pump++
        ) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(preferences.started.isCompleted, isTrue);
        expect(find.text('Đang đăng xuất…'), findsOneWidget);
        expect(learning.readProgress, isEmpty);

        // These are real pointer/keyboard/back events against the app, after the
        // lesson clear has finished but another repository is still clearing.
        await tester.tap(find.text('Học'), warnIfMissed: false);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(milliseconds: 20));
        expect(learning.stage, LearningStage.home);
        expect(learning.readProgress, isEmpty);
        expect(
          preferences.values.containsKey(
            LocalLessonProgressRepository.storageKey,
          ),
          isFalse,
        );

        preferences.release.complete();
        await tester.pumpAndSettle();
        expect(find.text('Đang đăng xuất…'), findsNothing);
        expect(onboarding.stage, OnboardingStage.welcome);
        expect(
          await LocalLessonProgressRepository(preferences: preferences).load(),
          isEmpty,
        );
        expect(
          preferences.values.containsKey(LocalOnboardingRepository.storageKey),
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
