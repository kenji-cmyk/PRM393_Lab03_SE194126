# Android target

Reserved for the Android Flutter project. Generate it from the repository root
after confirming the application ID; do not create a second nested Flutter app.

Setup will add Gradle files, wrapper, manifest, and application entry point.
FlutterFire places the real configuration at `android/app/google-services.json`.
Register the debug SHA fingerprint for Google Sign-In. Android 13+ notification
permission handling belongs to the integration stage.

No Android project or Firebase connection is implemented in this scaffold.
