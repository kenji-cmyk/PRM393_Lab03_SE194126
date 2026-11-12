# Admin callable emulator integration checks

This suite uses the real exported admin callables with Auth and Firestore
emulators. It seeds synthetic users only in `demo-vetalife-admin` and refuses
to run unless the Auth/Firestore hosts and project match that isolated target.
No production credentials, custom claims, users or documents are changed.

Install the repository's Functions dependencies first (`npm.cmd --prefix
functions ci`) and use Java plus the Firebase CLI already used by this project.
From the repository root on Windows:

```powershell
$env:GCLOUD_PROJECT = 'demo-vetalife-admin'
firebase.cmd emulators:exec --config firebase.admin-test.json --only auth,firestore,functions --project demo-vetalife-admin "node --test --test-concurrency=1 functions/test-admin/admin-emulator.test.js"
```

The `runtime` fixture re-exports the actual admin endpoints from
`functions/src/admin-functions.js`. It deliberately avoids importing the AI and
report entry points, so the check does not read real `.env` files or require
Gemini/Cloudinary secrets or configuration. Node resolves the already installed
dependencies from `functions/node_modules`; no generated dependency trees or
filesystem junctions are checked in.

Checks exercise authenticated callable HTTP requests, ordinary-user denial,
live admin claim removal, disabled administrator denial, bounded pagination,
exact search, profile field filtering, real activity counts, account state
updates, session revocation, mandatory audit records and denied direct audit
reads through Firestore rules. Permission-denied emulator logs are expected for
negative assertions. The suite clears Auth accounts in its fixed demo project
at setup; do not share that emulator project with another active test session.
