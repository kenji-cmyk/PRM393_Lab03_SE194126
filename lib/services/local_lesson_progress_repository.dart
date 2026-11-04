import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson.dart';
import 'lesson_progress_repository.dart';

class LocalLessonProgressRepository implements LessonProgressRepository {
  LocalLessonProgressRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  static const storageKey = 'vetalife.preview.lesson-progress.v1';
  final SharedPreferencesAsync _preferences;
  Future<void> _pending = Future<void>.value();

  @override
  Future<List<LessonReadProgress>> load() async {
    final stored = await _preferences.getString(storageKey);
    if (stored == null) return [];
    final json = jsonDecode(stored);
    if (json is! List || json.length > knownLessonIds.length) {
      throw const FormatException('Invalid progress storage');
    }
    final byId = <String, LessonReadProgress>{};
    for (final item in json) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid progress entry');
      }
      final progress = LessonReadProgress.fromJson(item);
      if (byId.containsKey(progress.lessonId)) {
        throw const FormatException('Duplicate progress identity');
      }
      byId[progress.lessonId] = progress;
    }
    return byId.values.toList()..sort((a, b) => b.readAt.compareTo(a.readAt));
  }

  @override
  Future<void> save(LessonReadProgress progress) => _serialize(() async {
    final validated = LessonReadProgress.fromJson(progress.toJson());
    final records = await load();
    // Read status records the first explicit completion, not a new event on retry.
    if (records.any((item) => item.lessonId == validated.lessonId)) return;
    records.add(validated);
    await _preferences.setString(
      storageKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  });

  @override
  Future<void> clearPreview() =>
      _serialize(() => _preferences.remove(storageKey));

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
