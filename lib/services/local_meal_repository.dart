import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';
import 'meal_repository.dart';

class LocalMealRepository implements MealRepository {
  LocalMealRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'vetalife.preview.meals.v1';
  final SharedPreferencesAsync _preferences;
  Future<void> _pending = Future<void>.value();

  @override
  Future<List<MealRecord>> load() async {
    final stored = await _preferences.getString(storageKey);
    if (stored == null) return [];
    final json = jsonDecode(stored);
    if (json is! List) throw const FormatException('Invalid journal');
    final records = json.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid journal record');
      }
      return MealRecord.fromJson(item);
    }).toList();
    records.sort((a, b) => b.draft.eatenAt.compareTo(a.draft.eatenAt));
    return records;
  }

  @override
  Future<void> save(MealRecord record) => _serialize(() async {
    // Parse before any writes so malformed data cannot erase an existing journal.
    MealRecord.fromJson(record.toJson());
    final records = await load();
    records.removeWhere((item) => item.id == record.id);
    records.add(record);
    await _preferences.setString(
      storageKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  });

  @override
  Future<void> clear() => _serialize(() => _preferences.remove(storageKey));

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
