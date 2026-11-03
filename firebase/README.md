# Firebase configuration scaffold

Primary baseline: Cloud-Enabled Lab 3 sections 5-6 and Preparation Guide v5.
Required services: Authentication, Cloud Storage, Cloud Messaging, Analytics,
Crashlytics, and Remote Config. Use the student's own Firebase project.

| File | Purpose / current status |
| --- | --- |
| `storage.rules` | Existing deny-all placeholder; define owner-scoped `reports/{uid}/...` rules and verify before deployment |
| `remote-config-defaults.json` | Empty placeholder; define at least two behavior-changing parameters after Lab 2 scope is known |
| `firestore.rules` | Deny-all placeholder for a topic that stores user data in Firestore |
| `firestore.indexes.json` | Empty index definition; add indexes needed by actual queries |

No rules are deployed and no Firebase project or cloud resource is configured.
Confirm Cloud Storage availability/billing during integration; substitution needs
lecturer approval under the selected handout.

At setup add actual Firebase CLI/project configuration, generate FlutterFire
options, enable Google Sign-In and Analytics, and register the Android signing
fingerprint. Isolate SDK adapters in `lib/firebase/` behind `lib/services/`;
Views must not call SDKs directly.

The alternate MobAI handout additionally requires Firestore CRUD, two collections,
queries, realtime updates, and PDF metadata. These are reference requirements,
conditional on approved scope here. Final Assignment storage constraints differ;
defer that assignment's configuration.
