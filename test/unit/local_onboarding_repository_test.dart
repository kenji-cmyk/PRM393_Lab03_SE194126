import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nep_lanh/models/habit_goal.dart';
import 'package:nep_lanh/models/user_profile.dart';
import 'package:nep_lanh/services/local_onboarding_repository.dart';

class _Preferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  final failures = <String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    if (failures.contains('write')) throw StateError('storage unavailable');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (failures.contains('write')) throw StateError('storage unavailable');
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Preferences preferences;
  late LocalOnboardingRepository repository;
  final profile = UserProfile(
    displayName: 'Nguyễn Ánh',
    birthDate: DateTime(2000, 2, 29),
    weightKg: 62.5,
    heightCm: 170.5,
    goal: HabitGoal.readDaily,
  );

  setUp(() {
    preferences = _Preferences();
    repository = LocalOnboardingRepository(preferences: preferences);
  });

  test('new preview has no saved profile', () async {
    expect(await repository.load(), isNull);
  });

  test(
    'a new repository restores the date-only profile and selected goal',
    () async {
      await repository.save(profile);
      final restored = await LocalOnboardingRepository(preferences: preferences)
          .load();
      expect(restored!.toJson(), profile.toJson());
      final stored = jsonDecode(
        preferences.values[LocalOnboardingRepository.storageKey]!,
      ) as Map<String, dynamic>;
      expect(stored['birthDate'], '2000-02-29');
      expect(stored.containsKey('age'), isFalse);
    },
  );

  test(
    'clear removes the profile without clearing unrelated preferences',
    () async {
      preferences.values['unrelated_setting'] = 'keep';
      await repository.save(profile);
      await repository.clear();
      expect(await repository.load(), isNull);
      expect(preferences.values['unrelated_setting'], 'keep');
    },
  );

  test(
    'corrupt storage remains an error rather than a new empty profile',
    () async {
      for (final value in ['{broken', '[]', '{"displayName":"Nguyễn Ánh"}']) {
        preferences.values[LocalOnboardingRepository.storageKey] = value;
        await expectLater(repository.load(), throwsFormatException);
        expect(preferences.values[LocalOnboardingRepository.storageKey], value);
      }
    },
  );

  test(
    'save failure propagates and leaves the previously saved profile intact',
    () async {
      await repository.save(profile);
      final previous = preferences.values[LocalOnboardingRepository.storageKey];
      preferences.failures.add('write');
      await expectLater(repository.save(profile), throwsStateError);
      expect(
        preferences.values[LocalOnboardingRepository.storageKey],
        previous,
      );
    },
  );
}
