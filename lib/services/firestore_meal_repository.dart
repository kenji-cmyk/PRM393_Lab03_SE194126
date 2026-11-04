import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/meal.dart';
import 'meal_repository.dart';

class FirestoreMealRepository implements MealRepository {
  FirestoreMealRepository(FirebaseFirestore firestore, String uid)
    : _meals = firestore.collection('users').doc(uid).collection('meals');

  final CollectionReference<Map<String, dynamic>> _meals;

  @override
  Future<List<MealRecord>> load() async {
    // Use the server so denied/network reads never masquerade as an empty journal.
    final snapshot = await _meals
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    final records = snapshot.docs.map((doc) {
      final data = doc.data();
      if (data['id'] != doc.id) {
        throw const FormatException('Mismatched meal identity');
      }
      return MealRecord.fromJson(data);
    }).toList();
    records.sort((a, b) => b.draft.eatenAt.compareTo(a.draft.eatenAt));
    return records;
  }

  @override
  Future<void> save(MealRecord record) async {
    final data = record.toJson();
    MealRecord.fromJson(data);
    await _meals
        .doc(record.id)
        .set({...data, 'updatedAt': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 20));
  }

  @override
  Future<void> clear() async {
    // Signing out clears session state; cloud records remain for their owner.
  }
}
