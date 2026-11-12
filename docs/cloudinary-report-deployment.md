# Cloudinary PDF backend

**Superseded for the active app:** report save/open now uses private Firestore
storage without Functions or billing. See [Firestore reports](firestore-reports.md).
The remaining text documents the optional legacy Cloudinary backend only.

Active Firebase project: `vetalife-24f03`.

On 2026-11-12, the supplied Cloudinary configuration was verified against the
live service. A synthetic PDF uploaded with authenticated delivery (HTTP 200),
downloaded using the existing report service's signed URL (HTTP 200, PDF bytes
verified), and denied unsigned download (HTTP 401). The synthetic asset was
deleted. No personal report was uploaded.

Local configuration is prepared in Git-ignored files:

| File | Values |
| --- | --- |
| `functions/.env.vetalife-24f03` | Cloud name, API key, signed report upload preset |
| `functions/.env.local` | Same non-secret values for Firebase Emulator |
| `functions/.secret.local` | `CLOUDINARY_API_SECRET` for Firebase Emulator |

The API secret was removed from the shared `functions/.env` after being moved
to `.secret.local`. Do not put it in Flutter, web assets or tracked example files.
Replace secrets exposed in chat before using them for a public deployment.

## Remaining production steps

The live billing readback confirmed `billingEnabled: false`. Production report
Functions are not deployed; the phone's upload/download endpoints still return
404. Cloudinary configuration and APK rebuilds cannot deploy these endpoints.
No Firebase billing, Secret Manager or production Functions changes were made.

After the project owner enables a suitable Firebase billing plan, set the
secret using the secure CLI prompt and deploy only the two report endpoints:

```powershell
firebase.cmd functions:secrets:set CLOUDINARY_API_SECRET --project vetalife-24f03
firebase.cmd deploy --config firebase.functions.legacy.json --project vetalife-24f03 --only functions:createReportUploadSignature,functions:getReportDownloadUrl
```

Enter the current Cloudinary secret at the prompt, never in command history.
The project parameter file supplies the other three Cloudinary values. Do not
deploy unrelated meal AI or admin Functions as part of this report rollout.

Verify deployment by calling without authentication (expect authentication denial
instead of 404), then test a signed-in phone report end to end. Test owner-only
access, account switching, upload cancellation and retry. Rebuilding the APK is
not required just to change these server parameters or activate these endpoints.

Sanitized configuration and live-test evidence:
`evidence/cloud/cloudinary-report-readiness-2026-11-12.json`.
