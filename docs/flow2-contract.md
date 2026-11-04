# Flow 2 implementation contract

Flow: home → entry → optional image recognition → ingredient confirmation →
analysis → result → explicit journal save. All edits/confirmation precede AI
analysis; failures preserve the draft, and cancelled work cannot apply stale
results. The preview path provides labelled local book matching, never fake AI
or fake image recognition. Cloud mode uses Firebase AI Logic with the Gemini
Developer API, initialized through `firebase_ai` and protected by App Check.

## JSON models (camelCase)

- Ingredient: `{name, amount, preparation}` (all strings; amount/preparation may
  be empty because the picture does not establish them).
- Draft: `{id, name, mealType, eatenAt, ingredients, notes}`. `mealType` is
  `breakfast|lunch|dinner|snack`; `eatenAt` is UTC ISO-8601. IDs are generated
  once for idempotent save; images are transient, absent from journal JSON.
- Recognition: `{mealName, ingredients, ocrText, warnings}`. All ingredients
  are provisional. OCR is text extraction, separate from visual food guesses.
- BookReference: `{id, chapterId, title, printedPage, pdfPage, summary}`.
- HealthConnection: `{topic, explanation, referenceIds: [id]}`. These describe
  book topics in the context of dietary patterns, never a diagnosis or a
  promised risk reduction from one meal.
- Analysis: `{title, summary, highlights: [string], improvements: [string],
  profileNote, limitations: [string], references: [BookReference],
  healthConnections: [HealthConnection], mode: gemini|localBook}`.
- Record: `{id, draft: Draft, analysis: Analysis, savedAt: UTC ISO-8601}`.

## Default cloud AI boundary — Spark

`AiLogicMealIntelligence` implements the existing `MealIntelligence` interface:

- `recognize(photo)` → Recognition. The app requires its signed-in cloud
  session and explicit upload consent. Send image bytes and MIME type through
  the SDK, at most 4 MiB; supported types are JPEG, PNG and WebP. Recognition
  does not include profile metadata or persist the photo.
- `analyze(draft, profile)` → Analysis after the ViewModel's explicit ingredient
  confirmation and consent gates. The current authenticated session provides
  its loaded profile; only derived age, weightKg, heightCm and goal enter the
  prompt. Name, full DOB and UID are omitted. This is client-side profile
  preparation, not an authoritative server re-read of `users/{uid}`.
- Match confirmed ingredient names to the 15 curated entries in
  `assets/content/meal-knowledge.json`. Structured model output contains source
  IDs; the app validates them against the selected entries and resolves actual
  titles/pages locally. Unknown sources or unsupported health-topic references
  are rejected. User text, OCR and images are data, never instructions.
- Firebase AI Logic console setup provisions provider access. The Flutter app
  uses its ordinary Firebase configuration and App Check; it contains no Gemini
  API key, Secret Manager call or default callable dependency. `GEMINI_MODEL`
  selects a compatible model; the default is `gemini-3.6-flash` and the chosen
  model must be available to the project on Spark.

Project setup has confirmed `gemini-developer-api` for Android/web and
`ENFORCED` for the AI Logic App Check service, without changing billing.
The App Check API is enabled, and a temporary-token exchange plus a non-personal
`gemini-3.6-flash` connectivity request returned HTTP 200. The temporary token
was revoked afterward. Web reCAPTCHA provider/site key and runtime debug-token
registration remain; this healthcheck does not verify native camera or meal
recognition/analysis accuracy.

Client prompts, corpus and validators can be inspected or modified by a client.
They improve application behavior but do not form a trusted server security
boundary. App Check enforcement and Firebase AI Logic/provider quotas protect
the API path. The old backend's 40/day and 6/minute per-UID quota does not apply
to this direct SDK path; no equivalent local counter is claimed as enforcement.

`functions/` retains the previous Node callables as an optional legacy Blaze
implementation, selected only through `firebase.functions.legacy.json`. Its
Secret Manager configuration, server profile read and quota transaction are
separate from the default Spark app composition.

## Storage and privacy

Local preview uses a separate shared-preferences journal key, cleared on
preview sign-out. Cloud journal is owner-scoped `users/{uid}/meals/{id}`;
photos are not stored. Saving the same ID overwrites that entry, not a second
meal. The profile and analysis stay within the authenticated user session.
Users explicitly accept the cloud upload before photos or confirmed meal
data/profile metadata are sent for AI processing.

## Flutter integration

`MealViewModel` owns confirmation, consent, draft retention and cancellation.
`AppDependencies` selects the cloud AI Logic adapter or explicitly local preview
adapter. `MealFlowScreen` renders those states without importing AI SDKs.
Firebase Auth/Firestore emulators may be used for their own services; AI Logic
is not emulated by this project and model requests still access the real API.
