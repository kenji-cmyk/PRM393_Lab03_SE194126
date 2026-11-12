# Private PDF reports on Firebase Spark

The active cloud app stores PDF reports directly in Firestore on
`vetalife-24f03`. It no longer needs a Cloudinary signing backend, Firebase
Functions, Firebase Storage or a billing upgrade for report save/open.

The preview app continues to generate PDF files locally without uploading.
The admin dashboard and Google sign-in configuration are unchanged.

## Storage and access

Each export creates an immutable manifest under
`users/{uid}/reports/{reportId}` and binary `chunks/{index}` documents. A single
atomic batch writes the manifest and every chunk. Reports are limited to **5 MiB**,
with **256 KiB** chunks and at most 20 chunks. The raw batch remains comfortably
below Firestore's 10 MiB request limit; each document is below its 1 MiB limit.
The byte payload field is excluded from indexing.

Firestore Rules require the authenticated UID to match the owner path, a saved
profile, a valid manifest, exact chunk indexes and sizes, and a server timestamp.
Reports cannot be overwritten, appended later or deleted from the app. Other
users and unauthenticated clients cannot read/list/write these documents.
An owner can submit incomplete metadata outside the app; the reader rejects
missing, malformed or truncated chunks instead of opening an incomplete PDF.

The report screen shows the 10 most recent valid manifests and supports opening
saved PDFs after app restart. Reads require the server. Account changes discard
pending results, and the screen does not show database paths or private contents
belonging to a previous session.

Firestore cannot abort a batch that has already been sent. Cancel/timeout stops
waiting for success but the private report can still finish saving. Check the
saved report list before retrying. The same service keeps its upload lock until
the original batch settles, preventing an overlapping save after a timeout.

## Quota and rollout

This uses the existing Spark Firestore quota; it is intended for a small app,
not large-scale file storage. A maximum-size report writes 21 documents; opening
it reads 21, plus any history query. Stored PDFs consume the same database quota
as profiles and meals. Monitor Firebase Console > Firestore > Usage. If the free
quota is exhausted, requests fail; this change does not enable billing. Manage
old reports from a trusted administrator environment if storage fills up.

Existing Cloudinary files are not migrated automatically. Its server code and
ignored local configuration remain available for a future optional deployment,
but the active report composition uses `FirestoreReportService`.

Deploy rules/index configuration before installing the new app:

```powershell
firebase.cmd deploy --project vetalife-24f03 --only firestore:rules,firestore:indexes
flutter.bat build apk --debug --dart-define=APP_MODE=cloud
```

No Cloudinary API secret is included in the APK. The build still uses the
registered Android debug signing key and App Check token for device testing.

## Verification

Security tests use the disposable `demo-vetalife-rules` emulator project:

```powershell
firebase.cmd emulators:exec --only firestore --project demo-vetalife-rules "npm.cmd --prefix functions run test:rules"
flutter.bat test test/unit/firestore_report_service_test.dart test/unit/report_view_model_test.dart test/widget/report_history_test.dart
```

The rules suite includes owner/cross-account/unauthenticated access, immutable
records, field/length/index validation and a successful maximum-size batch.
Storage tests cover round-trip byte reconstruction, invalid input, missing or
corrupted parts, account changes, cancel/timeout and late-commit handling.

Official limits: https://firebase.google.com/docs/firestore/quotas.

## Verified rollout on 2026-11-12

- Firestore rules/indexes deployed to `vetalife-24f03`; production rules readback
  matches local source. The binary payload index exemption is explicit.
- Billing readback remains disabled.
- Flutter Analyze passed; 200 tests passed and 2 explicitly opt-in AI live tests
  were skipped. Firestore Emulator rules suite: 21 passed, including 5 MiB.
- Cloud Android debug APK built, installed as an update and launched on CPH2799.
- Device screen showed save success and the saved-report entry. A read-only
  production metadata check confirmed a 14,944-byte PDF stored as one chunk.
  Native PDF viewer opening was not automated in this verification.

Sanitized evidence: `evidence/cloud/firestore-report-readback-2026-11-12.json`.
