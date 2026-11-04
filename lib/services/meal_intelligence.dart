import '../models/meal.dart';
import '../models/user_profile.dart';

abstract interface class MealIntelligence {
  bool get isCloud;
  bool get supportsImages;
  Future<MealRecognition> recognize(MealPhoto photo);
  Future<MealAnalysis> analyze(MealDraft draft, UserProfile profile);
}

class MealServiceException implements Exception {
  const MealServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
