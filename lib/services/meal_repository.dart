import '../models/meal.dart';

abstract interface class MealRepository {
  Future<List<MealRecord>> load();
  Future<void> save(MealRecord record);

  /// Used only for clearing explicit local preview data on sign-out.
  Future<void> clear();
}
