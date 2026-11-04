import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/meal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/services/book_meal_intelligence.dart';
import 'package:vetalife/services/local_meal_repository.dart';
import 'package:vetalife/services/meal_intelligence.dart';
import 'package:vetalife/services/meal_photo_picker.dart';

final _profile = UserProfile(
  displayName: 'Nguyễn Ánh',
  birthDate: DateTime(2000, 2, 29),
  weightKg: 62.5,
  heightCm: 170.5,
  goal: HabitGoal.addVegetables,
);

MealAnalysis _analysis() => MealAnalysis(
  title: 'Đối chiếu',
  summary: 'Nội dung',
  highlights: const [],
  improvements: const [],
  profileNote: 'Mục tiêu',
  limitations: const ['Chưa rõ khẩu phần.'],
  references: const [],
  healthConnections: const [],
  mode: 'localBook',
);

MealDraft _draft(
  List<String> names, {
  String id = 'meal-1',
  String notes = '',
}) => MealDraft(
  id: id,
  name: 'Bữa ăn',
  mealType: MealType.lunch,
  eatenAt: DateTime(2026, 11, 3, 12, 30),
  notes: notes,
  ingredients: names.map((name) => MealIngredient(name: name)).toList(),
);

MealRecord _record({String id = 'meal-1', String name = 'Bữa ăn'}) =>
    MealRecord(
      id: id,
      draft: _draft(['Đậu hũ'], id: id).copyWith(name: name),
      analysis: _analysis(),
      savedAt: DateTime(2026, 11, 3, 12, 45),
    );

class _Preferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  final failures = <String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    if (failures.contains('write')) throw StateError('disk full');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (failures.contains('write')) throw StateError('disk full');
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('local meal journal', () {
    late _Preferences preferences;
    late LocalMealRepository repository;
    setUp(() {
      preferences = _Preferences();
      repository = LocalMealRepository(preferences: preferences);
    });

    test(
      'same meal ID updates one entry and restores from another repository',
      () async {
        await repository.save(_record());
        await repository.save(_record(name: 'Món đã sửa'));
        final restored = await LocalMealRepository(preferences: preferences)
            .load();
        expect(restored, hasLength(1));
        expect(restored.single.draft.name, 'Món đã sửa');
        expect(restored.single.draft.eatenAt, DateTime(2026, 11, 3, 12, 30));
      },
    );

    test('concurrent saves on one repository retain both meal IDs', () async {
      await Future.wait([
        repository.save(_record(id: 'one')),
        repository.save(_record(id: 'two')),
      ]);
      expect(
        (await repository.load()).map((item) => item.id),
        containsAll(['one', 'two']),
      );
    });

    test(
      'corrupt existing journal is never overwritten by a new save',
      () async {
        for (final value in ['{broken', '{}', '[{"id":"broken"}]']) {
          preferences.values[LocalMealRepository.storageKey] = value;
          await expectLater(repository.load(), throwsFormatException);
          await expectLater(repository.save(_record()), throwsFormatException);
          expect(preferences.values[LocalMealRepository.storageKey], value);
        }
      },
    );

    test(
      'failed write preserves old data and does not block later saves',
      () async {
        await repository.save(_record());
        final original = preferences.values[LocalMealRepository.storageKey];
        preferences.failures.add('write');
        await expectLater(
          repository.save(_record(id: 'two')),
          throwsStateError,
        );
        expect(preferences.values[LocalMealRepository.storageKey], original);
        preferences.failures.remove('write');
        await repository.save(_record(id: 'two'));
        expect(await repository.load(), hasLength(2));
      },
    );

    test(
      'clear removes personal meal data while preserving unrelated settings',
      () async {
        preferences.values['theme'] = 'light';
        await repository.save(_record());
        await repository.clear();
        expect(await repository.load(), isEmpty);
        expect(preferences.values, {'theme': 'light'});
      },
    );
  });

  group('source-grounded local matching', () {
    late BookMealIntelligence intelligence;
    setUp(() {
      intelligence = BookMealIntelligence(
        loadKnowledge: () =>
            File('assets/content/meal-knowledge.json').readAsString(),
      );
    });

    test(
      'confirmed food names return actual book pages and valid reference links',
      () async {
        final result = await intelligence.analyze(
          _draft(['Đậu hũ', 'gạo lứt']),
          _profile,
        );
        final ids = result.references.map((item) => item.id).toSet();
        expect(ids, contains('beans-protein-fibre'));
        expect(ids, contains('whole-grains'));
        expect(
          result.references.every((ref) => ref.pdfPage == ref.printedPage + 2),
          isTrue,
        );
        expect(
          result.healthConnections.every(
            (item) => item.referenceIds.every(ids.contains),
          ),
          isTrue,
        );
        expect(result.mode, 'localBook');
        expect(result.summary, contains('chưa phải phân tích Gemini'));
        expect(intelligence.isCloud, isFalse);
        MealAnalysis.fromJson(result.toJson());
      },
    );

    test(
      'unknown foods and ingredient words in notes do not invent book evidence',
      () async {
        final result = await intelligence.analyze(
          _draft([
            'Món chưa rõ thành phần',
          ], notes: 'Đậu hũ, gạo lứt, rau xanh'),
          _profile,
        );
        expect(result.references, isEmpty);
        expect(result.healthConnections, isEmpty);
        expect(result.summary, contains('Chưa tìm được đoạn sách'));
      },
    );

    test('ordinary rice is not silently classified as a whole grain', () async {
      final result = await intelligence.analyze(
        _draft(['cơm', 'gạo', 'bánh mì']),
        _profile,
      );
      expect(
        result.references.map((item) => item.id),
        isNot(contains('whole-grains')),
      );
    });

    test('okra and peanuts do not match the generic bean keyword', () async {
      final result = await intelligence.analyze(
        _draft(['Đậu bắp', 'đậu phộng']),
        _profile,
      );
      expect(
        result.references.map((item) => item.id),
        isNot(contains('beans-protein-fibre')),
      );
    });

    test(
      'unaccented names still retrieve the confirmed Vietnamese ingredient',
      () async {
        final result = await intelligence.analyze(_draft(['dau hu']), _profile);
        expect(
          result.references.map((item) => item.id),
          contains('beans-protein-fibre'),
        );
      },
    );

    test('tamarind drink does not retrieve sesame or nut evidence', () async {
      final result = await intelligence.analyze(_draft(['nước me']), _profile);
      expect(
        result.references.map((item) => item.id),
        isNot(contains('nuts-seeds')),
      );
    });

    test('accented sesame names still retrieve the seeds reference', () async {
      for (final ingredient in ['mè', 'hạt mè']) {
        final result = await intelligence.analyze(
          _draft([ingredient]),
          _profile,
        );
        expect(
          result.references.map((item) => item.id),
          contains('nuts-seeds'),
          reason: 'Confirmed $ingredient should match sesame evidence.',
        );
      }
    });

    test(
      'local matching never fabricates a photo recognition result',
      () async {
        final photo = MealPhoto(
          bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
          mimeType: 'image/jpeg',
          fileName: 'meal.jpg',
        );
        expect(intelligence.supportsImages, isFalse);
        await expectLater(
          intelligence.recognize(photo),
          throwsA(isA<MealServiceException>()),
        );
      },
    );
  });

  test('analysis parser rejects connections to unknown source IDs', () {
    final data = _analysis().toJson();
    data['healthConnections'] = [
      {
        'topic': 'Tim mạch',
        'explanation': 'Nhận xét',
        'referenceIds': ['invented-source'],
      },
    ];
    expect(() => MealAnalysis.fromJson(data), throwsFormatException);
  });

  test('meal records cannot disguise a different draft identity', () {
    final json = _record().toJson();
    json['id'] = 'another-meal';
    expect(() => MealRecord.fromJson(json), throwsFormatException);
  });

  test(
    'photo byte signature determines supported MIME, not the file extension',
    () {
      expect(
        imageMimeType(Uint8List.fromList([0xff, 0xd8, 0xff])),
        'image/jpeg',
      );
      expect(
        imageMimeType(
          Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        ),
        'image/png',
      );
      expect(
        imageMimeType(Uint8List.fromList(utf8.encode('RIFF1234WEBP'))),
        'image/webp',
      );
      expect(
        imageMimeType(Uint8List.fromList(utf8.encode('not an image.jpg'))),
        isNull,
      );
    },
  );
}
