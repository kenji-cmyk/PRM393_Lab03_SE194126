import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import 'onboarding_repository.dart';

/// Each instance is bound to one authenticated UID for its whole lifetime.
class FirestoreOnboardingRepository implements OnboardingRepository {
  FirestoreOnboardingRepository(FirebaseFirestore firestore, String uid)
    : _document = firestore.collection('users').doc(uid) {
    if (uid.isEmpty) throw ArgumentError.value(uid, 'uid');
  }

  final DocumentReference<Map<String, dynamic>> _document;
  static const _timeout = Duration(seconds: 15);

  @override
  Future<UserProfile?> load() async {
    // Server-only: distinguish network failure from an actually missing profile.
    final snapshot = await _document
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final data = snapshot.data();
    return data == null ? null : UserProfile.fromJson(data);
  }

  @override
  Future<void> save(UserProfile profile) => _document
      .set({...profile.toJson(), 'updatedAt': FieldValue.serverTimestamp()})
      .timeout(_timeout);

  /// Signing out disposes the ViewModel; it must never delete a cloud profile.
  @override
  Future<void> clear() async {}
}
