# Nếp Lành - Flutter handoff

Status: flow 1 is implemented in Flutter using Provider, local preview storage,
and cloud Auth/Firestore adapters awaiting project configuration. Named flow-1
screens are state-routed within `FlowScreen`; proposed path URLs below are not
deep links. Flow 3 remains a design-derived specification. References:
[design specification](../design/DESIGN.md),
[Figma Final UI](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=2-3),
and [change log](../docs/design-change-log.md).

## Tokens to Flutter

Values below were read from the existing Figma design. Keep them centralized
under `lib/theme/` when implementing.

| Figma token/style | Verified value | Planned Flutter mapping |
| --- | --- | --- |
| color/brand/primary | `#2F6B4F` | `ColorScheme.primary` |
| color/brand/primary-container | `#E1F1E6` | `ColorScheme.primaryContainer` |
| color/surface/canvas | `#F7F8F4` | Scaffold background |
| color/text/primary | `#1F2B24` | Primary text color |
| color/text/secondary | `#526258` | Secondary text color |
| color/border/default | `#D6DFD7` | Outline/divider token |
| Type/Headline | Roboto Medium, 24 / 32 | Headline text style |
| Type/Title | Roboto Medium, 20 / 28 | Title text style |
| Type/Body | Roboto Regular, 16 / 24 | Body text style |
| Type/Body Small | Roboto Regular, 14 / 20 | Supporting text style |
| Type/Label | Roboto Medium, 14 / 20 | Labels |
| Spacing | 4, 8, 12, 16, 24, 32 | Named spacing constants |
| radius/medium | 12 | Controls |
| radius/large | 20 | Cards |
| radius/pill | 999 | Fully rounded shapes |

Font weights used by the file are Regular 400, Medium 500, and Bold 700.
Export any additional tokens from Figma rather than guessing values.

## Reusable components

Names in the Flutter column are proposed names, not implemented classes.

| Figma component | Observed variants/states | Planned Flutter component |
| --- | --- | --- |
| Button | Default, Focused, Loading, Disabled, Pressed | `AppButton` |
| Text Field | Default, Focused, Error, Filled, Disabled | `AppTextField` |
| Card | Default, Selected, Pressed | `AppCard` / book chapter item |
| Navigation Item | Selected, Unselected | Shared bottom-navigation destination |
| App Bar | Root, Back | Shared app bar |
| Dialog | Open, Confirmed, Destructive | Shared confirmation dialog |
| Loading | Processing, Complete | Shared loading/result states |
| Empty State | No meals, No results | Shared empty state |
| Error & Recovery | Offline, Retrying | Shared recoverable error |

The source Text Field's input container and value fill available width in all
five variants, including narrow date/age and weight/height columns. Preserve
those constraints in Flutter (for example, bounded/expanded row children)
rather than placing a fixed 320 dp input inside a narrow column.

Views render ViewModel state. Services own external SDK calls. Provider/Riverpod
selection remains pending; do not mix state-management approaches.

## Flow 1 - Personal information

Proposed route: `/onboarding/profile`; proposed screen/ViewModel:
`UserProfileScreen` / `UserProfileViewModel`. Navigation:
welcome -> profile -> goal selection -> home.

| Draft field | Type/format | Validation and behavior |
| --- | --- | --- |
| `displayName` | String | Required after trimming; retain the user's spelling |
| `birthDate` | Calendar date; persistence format `YYYY-MM-DD` | Real date, not later than today; display `dd/MM/yyyy`, do not shift it through UTC |
| `age` | Derived integer, display only | Recalculate from birth date using whether this year's birthday has occurred; do not store a second independently editable age |
| `weightKg` | Finite decimal number | Greater than zero; display `kg`; handle local decimal input |
| `heightCm` | Finite decimal number | Greater than zero; display `cm`; handle local decimal input |

These names are a draft model contract, not a deployed API/schema. Before
persistence, agree the Firebase account ownership, profile document path, rules,
and update behavior. Keep the draft on back navigation; validation errors must
not erase other fields. Save failure shows a retryable message while preserving
the draft. Disable duplicate submission while saving.

Age must use a date-only calculation, including birthday boundaries and valid
leap-day dates. Do not impose invented health ranges or derive BMI/medical advice.
Profile name, birth date, age, weight, and height are excluded from Analytics
parameters. Any Analytics event added later records the action without these values.

## Flow 3 - Book catalogue and reader

Proposed routes: `/learn` and `/learn/:lessonId`; proposed
`LessonCatalogViewModel` / `LessonDetailViewModel`. The design uses the book's
two parts rather than a single generic article.

Use [the curriculum](../docs/book-curriculum.md) and
`assets/content/lesson-catalog.json` as source-mapped planning metadata. Stable
lesson IDs, source titles, short display titles, part/category ordering, and
printed/PDF page references should remain separate from user progress.
No runtime asset loading or lesson content delivery is implemented yet.

In the current Figma prototype, 30 entries set string variables before opening
one shared reader; selection controls its title, exact source reference, and
section. Mark-read updates last-read feedback on weekly progress only. The form
uses prepared empty/filled/invalid snapshots rather than real text/date entry.
Neither mechanism persists user data or implements the production contracts below.
Static reaction inspection and screenshots at 360/412 dp have been reviewed;
no live browser/prototype interaction or native input test was run.

A user selects a part, selects a chapter/category, opens its detail, and marks
that selected lesson read. Returning to the catalogue/progress must retain the
chosen lesson identity and selected part. Read progress must be keyed by user and
lesson, rather than one global `lessonRead` flag. Catalogue loading, empty and
error states and persistence behavior remain implementation work.

The book is a local source under ignored `docs/requirements/`. Do not bundle the
774-page PDF or copy long passages into app assets. Lesson bodies require
source-based editorial work; a source-mapped table of contents is not the full
course.

## Verification to perform during implementation

- Form labels, keyboard types, date selection, date-only age calculation, and
  missing/invalid-value messages.
- Back/retry preserves drafts; loading prevents duplicate saves.
- Every chapter displays the matching lesson ID, source title, and page reference.
- Mark-read updates only the selected user's selected lesson; selection survives
  navigation.
- All three original flows remain reachable, including meal-error recovery.
- Components, typography, 48 dp targets, 14 sp minimum body text, and layouts at
  360/412 dp match the design.

These are pending implementation checks, not executed test results.
