import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firebase_bootstrap.dart';
import 'auth_service.dart';
import 'firestore_onboarding_repository.dart';
import 'onboarding_repository.dart';

/// Composition boundary; widgets never import Firebase SDKs.
abstract final class AppDependencies {
  static Future<AuthService> initializeCloud() async {
    await initializeFirebase();
    return FirebaseAuthService();
  }

  static OnboardingRepository repositoryFor(String uid) =>
      FirestoreOnboardingRepository(FirebaseFirestore.instance, uid);
}
