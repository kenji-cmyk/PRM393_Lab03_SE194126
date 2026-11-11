# Branch integration verification — 2026-11-12

Integrated `origin/vy` and `origin/dev/Khoi` into local `main`, after updating
to `origin/main` (`db8314e`). Both merges completed without conflicts:
`f9f176e` (vy), `dccadb0` (dev/Khoi).

## Results

| Check | Result |
| --- | --- |
| `flutter.bat analyze` | Passed; no issues |
| `flutter.bat test --reporter compact` | 174 passed; 2 live tests skipped |
| `flutter.bat build apk --debug` | Passed; `build/app/outputs/flutter-apk/app-debug.apk` |
| Functions `npm.cmd run check` | Passed |
| Functions `npm.cmd test` | 33 passed |
| Firestore rules tests on `demo-vetalife-rules` emulator | 14 passed |
| ARTEMIS offline pytest suite | 25 passed; 51 device attempts skipped |
| AI live harness syntax and offline configuration extraction | Passed with current and synthetic alternate Firebase configurations |

Independent review found one integration defect: the AI live harness retained
the previous Firebase project and app identifiers while reading the new API key.
The harness now derives its project, app ID, project number and API key from
the same web configuration in `lib/firebase_options.dart`, and checks consistency
before invoking the CLI. No live AI calls or temporary token registrations were
performed during verification.

The ARTEMIS offline rerun used the existing `tmp/e2e-tools` pytest installation,
disabled pytest caching, ignored two inaccessible stale pytest cache directories,
and used `tmp/merge-branches-pytest-20261112` for temporary files. Initial attempts
encountered missing global pytest and filesystem permissions; the final run passed.

Android build emitted SDK manager, Java native-access and Kotlin plugin migration
warnings, but completed successfully. Live Firebase/Cloudinary acceptance and
device/model ARTEMIS execution were not performed. Existing local document and
evidence changes were preserved. No remote push or deployment was performed.
