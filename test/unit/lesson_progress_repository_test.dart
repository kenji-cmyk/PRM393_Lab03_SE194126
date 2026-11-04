import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetalife/models/lesson.dart';
import 'package:vetalife/services/local_lesson_progress_repository.dart';

class _Preferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  final failures = <String>{};
  bool get failWrites => failures.contains('write');
  set failWrites(bool value) =>
      value ? failures.add('write') : failures.remove('write');
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) throw StateError('disk failure');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (failWrites) throw StateError('disk failure');
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LessonReadProgress _progress(String id, [int day = 4]) =>
    LessonReadProgress(lessonId: id, readAt: DateTime.utc(2026, 11, day));

void main() {
  test(
    'empty state, persistence, same-ID idempotency and preview cleanup',
    () async {
      final preferences = _Preferences();
      final repo = LocalLessonProgressRepository(preferences: preferences);
      expect(await repo.load(), isEmpty);
      await repo.save(_progress('p1-ch01'));
      await repo.save(_progress('p1-ch01', 5));
      final restored = await LocalLessonProgressRepository(
        preferences: preferences,
      ).load();
      expect(restored.length, 1);
      expect(restored.single.readAt, DateTime.utc(2026, 11, 4));
      await repo.clearPreview();
      expect(await repo.load(), isEmpty);
    },
  );
  test('concurrent writes serialize without losing another lesson; clear runs after writes', () async {
    final repo = LocalLessonProgressRepository(preferences: _Preferences());
    await Future.wait([
      repo.save(_progress('p1-ch01')),
      repo.save(_progress('p2-dd01')),
    ]);
    expect((await repo.load()).length, 2);
    await Future.wait([repo.save(_progress('p1-ch02')), repo.clearPreview()]);
    expect(await repo.load(), isEmpty);
  });
  test('corruption and failed writes preserve stored progress, failures do not poison queue', () async {
    final preferences = _Preferences();
    final repo = LocalLessonProgressRepository(preferences: preferences);
    await repo.save(_progress('p1-ch01'));
    final before = preferences.values[LocalLessonProgressRepository.storageKey];
    preferences.failWrites = true;
    await expectLater(repo.save(_progress('p1-ch02')), throwsStateError);
    await expectLater(repo.clearPreview(), throwsStateError);
    expect(
      preferences.values[LocalLessonProgressRepository.storageKey],
      before,
    );
    preferences.failWrites = false;
    await repo.save(_progress('p1-ch02'));
    expect((await repo.load()).length, 2);
    preferences.values[LocalLessonProgressRepository.storageKey] = '[{}]';
    await expectLater(repo.save(_progress('p2-dd01')), throwsFormatException);
    expect(
      preferences.values[LocalLessonProgressRepository.storageKey],
      '[{}]',
    );
    await repo.clearPreview();
    expect(await repo.load(), isEmpty);
  });
}
