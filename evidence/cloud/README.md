# Người 1 · Cloud & Private Report Evidence (`vetalife-lab3`, `2026-11-11`)

- **Branch:** `vy` (branched from `main` at `f45fe28`; no changes pushed to `main`)
- **Firebase project:** `vetalife-lab3` (`Spark` free plan; migrated from `vetalife-24f03` per team decision)
- **Cloudinary test environment:** `z1kbu8wz`, signed preset `vetalife_reports` (`type=authenticated`, `allowed_formats=pdf`, `overwrite=false`, PDF/ZIP delivery enabled, account Free tier limit `10 MB` = `10485760` bytes)
- **Device tested:** Android Emulator `Medium_Phone` (`API 34`, `emulator-5554`)

## Production Blocker (`FIREBASE-BILLING-01`)

- `vetalife-lab3` is on **Spark** (free tier). Cloud Functions v2 (`createReportUploadSignature`, `getReportDownloadUrl`) in `firebase.functions.legacy.json` were **not** deployed to production (`productionFunctionsDeployed: false`).
- All real Cloudinary PDF upload/download, `overwrite=false`, cross-UID denial, and `> 10 MiB` rejection checks were verified via **local Auth + Firestore + Functions Emulators (`--project vetalife-lab3`) communicating with the real Cloudinary account**.

## JSON Readbacks

- [cloudinary-setup-readback-2026-11-11.json](cloudinary-setup-readback-2026-11-11.json) — Project `vetalife-lab3` configuration, Remote Config v1 readback, Cloudinary preset/limit summary, Spark billing blocker, and verification status.
- [emulator-report-checks-2026-11-11.json](emulator-report-checks-2026-11-11.json) — Sanitized HTTP verification log against local Auth (`9099`) & Functions (`5001`) Emulators + live Cloudinary (`z1kbu8wz`):
  - Unauthenticated calls rejected (`HTTP 401 UNAUTHENTICATED`).
  - Owner signed PDF upload (`HTTP 200`, `raw`/`authenticated`) + duplicate `overwrite=false` (`existing: true`) + unsigned raw URL denied (`HTTP 401`) + 10-minute signed download (`HTTP 200`, `%PDF-` verified, `~600s` TTL).
  - Cross-UID download denied (`HTTP 403 PERMISSION_DENIED`: `Báo cáo không thuộc tài khoản hiện tại.`).
  - Server-side oversize upload (`10,747,904` bytes) rejected by Cloudinary (`HTTP 400`: `File size too large. Got 10747913. Maximum is 10485760.`).

## Captured Screenshots (`screenshots/`, PII & UIDs masked)

| File | Verified Scenario |
| --- | --- |
| [01-cloudinary-upload-preset.png](screenshots/01-cloudinary-upload-preset.png) | Cloudinary `vetalife_reports` preset (`Signed`, `Overwrite: false`, `Type: authenticated`, `Allowed formats: pdf`) |
| [02-cloudinary-security-pdf.png](screenshots/02-cloudinary-security-pdf.png) | Cloudinary Security (`Allow delivery of PDF and ZIP files` enabled) |
| [03-cloudinary-free-plan-limit.png](screenshots/03-cloudinary-free-plan-limit.png) | Cloudinary Free plan account cap (`10 MB max raw file size`) |
| [04-auth-google-signin-cancelled.png](screenshots/04-auth-google-signin-cancelled.png) | Google Sign-In cancelled cleanly (`Bạn đã hủy đăng nhập...`) |
| [05-cloud-home-after-reload.png](screenshots/05-cloud-home-after-reload.png) | Real Firebase Auth + Firestore save/reload on `vetalife-lab3` (profile & saved meal persisted after cold restart) |
| [06-firestore-user-doc-masked.png](screenshots/06-firestore-user-doc-masked.png) | Firestore Console `users/{uid}` structure (`profile`, `meals`, `lessonProgress`, UID/name masked) |
| [07-auth-account-switch-clean.png](screenshots/07-auth-account-switch-clean.png) | Sign-out & switch to second Google account with clean empty onboarding state |
| [08-report-upload-cancelled.png](screenshots/08-report-upload-cancelled.png) | Report PDF upload cancelled mid-flight cleanly (`Đã hủy thao tác. Bạn có thể thử lại.`) |
| [09-report-upload-network-error.png](screenshots/09-report-upload-network-error.png) | Report PDF upload failure recovery feedback when network/service is unavailable |
| [10-report-upload-cloudinary-uri.png](screenshots/10-report-upload-cloudinary-uri.png) | Real Cloudinary upload complete on Android (`cloudinary://authenticated/u_<masked>/reports/...pdf` + `Mở PDF`) |
| [11-report-opened-pdf-viewer.png](screenshots/11-report-opened-pdf-viewer.png) | Downloaded private PDF opened in Android viewer with bundled Vietnamese Roboto fonts |
| [12-cloudinary-assets-app-pdf.png](screenshots/12-cloudinary-assets-app-pdf.png) | Uploaded app PDF (`13.7 KB`, `PDF`, `Authenticated`, `via API`) in Cloudinary Media Library |
| [13-cloudinary-assets-synthetic-pdf.png](screenshots/13-cloudinary-assets-synthetic-pdf.png) | Synthetic emulator verification PDF (`99 Bytes`, `PDF`, `Authenticated`, `via API`) in Cloudinary Media Library |

## Handoff for Người 2 (`task/device-evidence`)

1. Pull branch `vy` (or merged `main`) to pick up `vetalife-lab3` configs (`android/app/google-services.json`, `lib/firebase_options.dart`, `firebase.json`, `web/firebase-messaging-sw.js`, `tool/register_app_check_debug.ps1`) and debug emulator cleartext allowlist (`android/app/src/debug/AndroidManifest.xml`, `android/app/src/debug/res/xml/network_security_config.xml`).
2. Share your test Google account + Android debug SHA-1 with Người 1 to add to `vetalife-lab3`, and register your device's App Check debug token via `.\tool\register_app_check_debug.ps1 -Platform android` before testing Flow 2 AI Logic.
3. For `EXPORT-02` (`cloudinary://...`) while `vetalife-lab3` remains on Spark, run with local Emulators (`--dart-define=APP_MODE=cloud --dart-define=USE_FIREBASE_EMULATORS=true`, `adb reverse` ports `9099`, `8080`, `5001`, `--project vetalife-lab3`). Do **not** mark production Cloud Functions deployment as passed while `FIREBASE-BILLING-01` remains open.

