import 'package:flutter_test/flutter_test.dart';

import 'package:nep_lanh/models/habit_goal.dart';
import 'package:nep_lanh/models/user_profile.dart';
import 'package:nep_lanh/utils/calendar_date.dart';

void main() {
  UserProfile profile({DateTime? birthDate}) => UserProfile(
    displayName: '  Nguyễn Minh  ',
    birthDate: birthDate ?? DateTime(2000, 11, 4),
    weightKg: 62.5,
    heightCm: 170,
    goal: HabitGoal.addVegetables,
  );

  test('age changes on birthday, without using hours or UTC shifts', () {
    final value = profile();
    expect(value.ageAt(DateTime(2026, 11, 3, 23, 59)), 25);
    expect(value.ageAt(DateTime(2026, 11, 4)), 26);
    expect(value.ageAt(DateTime(2026, 11, 5)), 26);
  });

  test('leap-day age uses calendar birthday boundary', () {
    final value = profile(birthDate: DateTime(2000, 2, 29));
    expect(value.ageAt(DateTime(2024, 2, 28)), 23);
    expect(value.ageAt(DateTime(2024, 2, 29)), 24);
    expect(value.ageAt(DateTime(2025, 2, 28)), 24);
    expect(value.ageAt(DateTime(2025, 3, 1)), 25);
  });

  test(
    'date-only round trip retains calendar components and stores no age',
    () {
      final value = profile(birthDate: DateTime.utc(2000, 1, 1, 23, 30));
      final json = value.toJson();
      expect(json['birthDate'], '2000-01-01');
      expect(json.containsKey('age'), isFalse);
      expect(json.containsKey('uid'), isFalse);
      expect(json['displayName'], 'Nguyễn Minh');
      final restored = UserProfile.fromJson(json);
      expect(restored.birthDate, DateTime(2000, 1, 1));
      expect(restored.weightKg, 62.5);
      expect(restored.heightCm, 170);
      expect(restored.goal, HabitGoal.addVegetables);
    },
  );

  test('every goal survives serialization', () {
    for (final goal in HabitGoal.values) {
      final json = {...profile().toJson(), 'goal': goal.name};
      expect(UserProfile.fromJson(json).goal, goal);
    }
  });

  test('strict parsing rejects normalized dates and incompatible fields', () {
    final invalidFields = <String, List<Object?>>{
      'displayName': ['', '   ', 123, null],
      'birthDate': [
        '2001-02-29',
        '2000-02-30',
        '2000-13-01',
        '0000-01-01',
        '01/01/2000',
        '2000-01-01T00:00:00Z',
        null,
      ],
      'weightKg': [0, -1, double.infinity, double.nan, '62.5', null],
      'heightCm': [0, -1, double.infinity, double.nan, '170', null],
      'goal': ['unknown', 0, null],
    };
    for (final field in invalidFields.entries) {
      for (final invalid in field.value) {
        expect(
          () =>
              UserProfile.fromJson({...profile().toJson(), field.key: invalid}),
          throwsFormatException,
          reason: '${field.key} must reject $invalid',
        );
      }
    }
  });

  test('display parser accepts real leap day and rejects inexact dates', () {
    expect(parseCalendarDate('29/02/2000', iso: false), DateTime(2000, 2, 29));
    for (final invalid in [
      '29/02/2001',
      '31/04/2000',
      '1/1/2000',
      '00/01/2000',
    ]) {
      expect(parseCalendarDate(invalid, iso: false), isNull);
    }
  });
}
