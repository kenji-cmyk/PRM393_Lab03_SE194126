import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/firebase_bootstrap.dart';
import '../firebase/app_check_bootstrap.dart';
import 'auth_service.dart';
import 'firestore_onboarding_repository.dart';
import 'onboarding_repository.dart';
import 'ai_logic_meal_intelligence.dart';
import 'firestore_meal_repository.dart';
import 'meal_intelligence.dart';
import 'meal_repository.dart';
import 'lesson_progress_repository.dart';
import 'firestore_lesson_progress_repository.dart';

/// Composition boundary; widgets never import Firebase SDKs.
abstract final class AppDependencies {
  static Future<AuthService> initializeCloud() async {
    await initializeFirebase();
    if (const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
      const host = String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
        defaultValue: '127.0.0.1',
      );
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    }
    return FirebaseAuthService();
  }

  static OnboardingRepository repositoryFor(String uid) =>
      FirestoreOnboardingRepository(FirebaseFirestore.instance, uid);

  static MealRepository mealsFor(String uid) =>
      FirestoreMealRepository(FirebaseFirestore.instance, uid);

  static LessonProgressRepository lessonsFor(String uid) =>
      FirestoreLessonProgressRepository(FirebaseFirestore.instance, uid);

  static MealIntelligence mealIntelligence() => AiLogicMealIntelligence(
    currentUserId: () => FirebaseAuth.instance.currentUser?.uid,
    ensureReady: AppCheckBootstrap.instance.requireAiReady,
  );
}
