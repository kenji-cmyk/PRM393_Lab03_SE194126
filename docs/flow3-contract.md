# Flow 3 implementation contract

Design nodes: weekly progress `6:213`, part-1 catalogue `6:257`, part-2 catalogue
`166:470`, shared reader `166:628` in the existing Lab 2 Figma file.

The catalogue preserves `assets/content/lesson-catalog.json`: 15 part-1 chapters,
12 part-2 Daily Dozen categories, and 3 supplementary part-2 entries. Stable IDs,
source titles, printed/PDF pages and source order must survive display changes.
Only the 27 core units count toward core completion. Opening a lesson does not
mark it read; the explicit reader button saves once for that ID.

## Content asset

New `assets/content/lesson-content.json`: schemaVersion 1 and `lessons` array.
Each entry: `{lessonId, summary, sections: [{heading, paragraphs: [string]}],
reflection, sourcePages: [{printedPage, pdfPage}]}`. All 30 catalogue IDs must
have a corresponding body. Content is short authored Vietnamese paraphrase,
grounded in inspected pages, not book scans or copied passages. `sourcePages`
refer to pages actually inspected for that body, with PDF = printed + 2. Keep
chapter start pages in the catalogue separate from body source pages. Do not
invent treatment instructions or portray chapter titles as clinical promises.

## Dart boundary

- `lib/models/lesson.dart`: `Lesson` (`id`, `partId`, `sourceTitle`,
  `displayTitle`, `printedPage`, `pdfPage`, `kind`, `isCore`, `body`);
  `LessonBody` (`lessonId`, `summary`, `sections`, `reflection`, `sourcePages`);
  `LessonSection` (`heading`, `paragraphs`); `LessonSourcePage` (`printedPage`,
  `pdfPage`); `LessonPart` (`id`, `displayTitle`, `units`); `LessonCatalog`
  (`bookTitle`, `authors`, `parts`, `lessons`, `coreCount`, `lessonById(id)`);
  `LessonReadProgress` (`lessonId`, `readAt`), with strict progress serialization.
- `AssetLessonCatalog.load()` joins both bundled assets and validates all IDs.
- `LessonProgressRepository`: `load() -> Future<List<LessonReadProgress>>`,
  `save(LessonReadProgress) -> Future<void>`, `clearPreview() -> Future<void>`.
  Local `clearPreview` removes preview state; cloud is a documented no-op.
- Local repository uses a separate shared-preferences key and does not fabricate
  completion. Cloud saves `users/{uid}/lessonProgress/{lessonId}` using owner
  rules and a server timestamp. It retains progress on sign-out.
- `LearningViewModel(repository:, loadCatalog?:, now?:)` owns asynchronous state,
  explicit read saves, errors, retries, idempotency, cancellation and cleanup.
  `LearningStage`: `home`, `progress`, `catalog`, `detail`.
  Properties: `stage`, `catalog`, `selectedPartId`, `selectedLesson`,
  `readProgress`, `completedCoreCount`, `lastReadLesson`, `isLoading`, `isSaving`,
  `errorMessage`. Methods: `initialize`, `retry`, `showHome`, `showProgress`,
  `showCatalog`, `selectPart(String)`, `openLesson(String)`, `back`,
  `markSelectedRead`, `clearPreviewSession`; `isRead(String)`.

## UI and application integration

`LearningFlowScreen` accepts `onHome` and `onJournal` callbacks and reads
`LearningViewModel`, optional `MealViewModel` and optional `OnboardingViewModel`
through Provider. The existing application/session owner supplies providers.
It reuses `AppTopBar`, `AppCard`, `AppButton`, theme tokens and `MealNavigation`.
No networking or Firebase SDK imports in widgets.

Progress reflects actual saved meal records in the local Monday–Sunday week,
not nutritional compliance. Future calendar dates do not count. Chart values,
text alternatives, zero states, highlights and read counts must agree. No mock
sample bars/completion. The reader preserves source identity and shows content,
source pages and an explicit mark-read action. Back returns to the same part;
navigation between all four destinations must work without discarding an active
meal save. Loading, failed reads/writes, retry and sign-out/session isolation are
part of the implementation, including 360/412 dp and enlarged text.
