# Android target

Flutter Android project generated at repository root; application ID
`vn.edu.fpt.nep_lanh`, minimum SDK 23. `flutter build apk --debug` builds the
explicit local preview. Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Gradle files, manifest, Internet permission and application entry point are implemented.
FlutterFire places the real configuration at `android/app/google-services.json`.
Register the debug SHA fingerprint for Google Sign-In. Android 13+ notification
permission handling belongs to the integration stage.

Google/Auth/Firestore code is implemented; Firebase remains unconfigured by user
choice. Follow [the setup guide](../docs/firebase-setup.md), then pass
`--dart-define=APP_MODE=cloud`. Release signing remains to be configured.

`kotlin.incremental=false` handles the observed Windows build layout where Pub
plugins live on C: and the project lives on D:. This disables Kotlin incremental
compilation, preserving other Gradle caching.
