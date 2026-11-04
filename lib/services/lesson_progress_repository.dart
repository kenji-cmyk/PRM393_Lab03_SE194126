import '../models/lesson.dart';

abstract interface class LessonProgressRepository {
  Future<List<LessonReadProgress>> load();
  Future<void> save(LessonReadProgress progress);

  /// Clears device preview state only. Cloud adapters retain the owner's data.
  Future<void> clearPreview();
}
