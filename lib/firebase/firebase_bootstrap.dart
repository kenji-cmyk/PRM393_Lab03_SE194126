import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'app_check_bootstrap.dart';

Future<void> initializeFirebase() async {
  await AppCheckBootstrap.instance.initializeWithFirebase(() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 20));
    }
  });
  // Personal profile data stays in memory only; signing out drops the VM.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}
