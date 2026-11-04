import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lesson.dart';
import 'lesson_progress_repository.dart';

class FirestoreLessonProgressRepository implements LessonProgressRepository {
  FirestoreLessonProgressRepository(FirebaseFirestore firestore, String uid)
    : _progress = firestore
          .collection('users')
          .doc(uid)
          .collection('lessonProgress');
  final CollectionReference<Map<String, dynamic>> _progress;

  @override
  Future<List<LessonReadProgress>> load() async {
    final snapshot = await _progress
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    final records = snapshot.docs.map((doc) {
      final data = doc.data();
      if (data.length != 3 ||
          data['lessonId'] != doc.id ||
          data['updatedAt'] is! Timestamp) {
        throw const FormatException('Invalid cloud progress');
      }
      return LessonReadProgress.fromJson({
        'lessonId': data['lessonId'],
        'readAt': data['readAt'],
      });
    }).toList();
    records.sort((a, b) => b.readAt.compareTo(a.readAt));
    return records;
  }

  @override
  Future<void> save(LessonReadProgress progress) async {
    final data = LessonReadProgress.fromJson(progress.toJson()).toJson();
    await _progress
        .doc(progress.lessonId)
        .set({...data, 'updatedAt': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 20));
  }

  @override
  Future<void> clearPreview() async {
    // Cloud progress survives sign-out. Provider lifetime clears session memory.
  }
}
