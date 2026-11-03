import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract interface class AuthService {
  Stream<String?> get userChanges;
  Future<void> signIn();
  Future<void> signOut();
}

class SignInCancelled implements Exception {
  const SignInCancelled();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  Future<void>? _googleReady;

  @override
  Stream<String?> get userChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<void> signIn() async {
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        await (_googleReady ??= GoogleSignIn.instance.initialize());
        final account = await GoogleSignIn.instance.authenticate();
        final credential = GoogleAuthProvider.credential(
          idToken: account.authentication.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelled();
      }
      rethrow;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request') {
        throw const SignInCancelled();
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb && _googleReady != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase session is already closed; never retain personal UI state.
      }
    }
  }
}
