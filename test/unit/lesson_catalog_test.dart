import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/models/lesson.dart';
import 'package:vetalife/services/lesson_catalog_service.dart';

import 'lesson_test_fixtures.dart';

void main() {
  test('authored runtime asset supplies a sourced body for each of the 30 catalogue units', () async {
    final catalog = await AssetLessonCatalog(
      loadString: (path) => File(path).readAsString(),
    ).load();
    expect(catalog.lessons.length, 30);
    expect(catalog.coreCount, 27);
    for (final lesson in catalog.lessons) {
      expect(lesson.body.lessonId, lesson.id);
      expect(lesson.body.sections, isNotEmpty);
      expect(lesson.body.sourcePages, isNotEmpty);
      expect(lesson.body.summary, isNot(contains('Synthetic unit-test')));
    }
  });
  test('source catalogue joins all 30 bodies in source order and counts 27 core units', () {
    final catalog = lessonFixture();
    expect(catalog.lessons.length, 30);
    expect(catalog.coreCount, 27);
    expect(catalog.parts.map((part) => part.id), ['part-1', 'part-2']);
    expect(catalog.parts[1].units.take(3).map((unit) => unit.id), [
      'p2-introduction',
      'p2-daily-dozen',
      'p2-dd01',
    ]);
    expect(catalog.parts[1].units.last.id, 'p2-conclusion');
    expect(
      catalog.lessonById('p1-ch01')!.sourceTitle,
      'Để không chết vì bệnh tim',
    );
    expect(catalog.lessonById('p2-dd01')!.printedPage, 373);
    expect(
      catalog.lessonById('p2-dd01')!.body.sourcePages.first.printedPage,
      37,
    );
    expect(catalog.lessonById('missing'), isNull);
    expect(catalog.lessonById('p2-introduction')!.isCore, isFalse);
  });
  test('missing, duplicate or unknown bodies and forged page offsets fail explicitly', () {
    for (final change in <void Function(Map<String, dynamic>)>[
      (json) => (json['lessons'] as List).removeLast(),
      (json) => (json['lessons'] as List)[1] = (json['lessons'] as List)[0],
      (json) => (json['lessons'] as List).first['lessonId'] = 'invented',
      (json) =>
          (json['lessons'] as List).first['sourcePages'][0]['pdfPage'] = 777,
    ]) {
      final content = contentFixture();
      change(content);
      expect(
        () => LessonCatalog.fromJson(catalogueFixture(), content),
        throwsFormatException,
      );
    }
    final catalogue = catalogueFixture();
    catalogue['parts'][0]['units'][0]['id'] = 'p1-ch99';
    expect(
      () => LessonCatalog.fromJson(catalogue, contentFixture()),
      throwsFormatException,
    );
  });
  test(
    'loader consumes both bundled paths and never creates fallback lessons',
    () async {
      final requested = <String>[];
      final loader = AssetLessonCatalog(
        loadString: (path) async {
          requested.add(path);
          return jsonEncode(
            path.endsWith('lesson-catalog.json')
                ? catalogueFixture()
                : contentFixture(),
          );
        },
      );
      expect((await loader.load()).coreCount, 27);
      expect(requested, [
        'assets/content/lesson-catalog.json',
        'assets/content/lesson-content.json',
      ]);
      final broken = AssetLessonCatalog(loadString: (_) async => '{}');
      await expectLater(broken.load(), throwsFormatException);
    },
  );
  test(
    'progress requires known ID, exactly two fields and canonical UTC date',
    () {
      final progress = LessonReadProgress(
        lessonId: 'p1-ch01',
        readAt: DateTime(2026, 11, 4, 12),
      );
      expect(
        LessonReadProgress.fromJson(progress.toJson()).readAt,
        progress.readAt.toUtc(),
      );
      for (final json in [
        {'lessonId': 'p1-ch99', 'readAt': '2026-11-04T12:00:00.000Z'},
        {'lessonId': 'p1-ch01', 'readAt': '2026-02-30T12:00:00.000Z'},
        {'lessonId': 'p1-ch01', 'readAt': '2026-11-04T12:00:00.000'},
        {...progress.toJson(), 'uid': 'someone'},
      ]) {
        expect(() => LessonReadProgress.fromJson(json), throwsFormatException);
      }
    },
  );
}
