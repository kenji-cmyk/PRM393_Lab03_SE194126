# Analytics plan

Plan defined before instrumentation (2026-11-09). Cloud mode sends events;
preview uses a no-op adapter. No names, email, birth dates, measurements,
meal text, notes, photos or raw exceptions are sent. Only Firebase Auth UID
identifies the session and is cleared on sign-out.

| Event | Trigger / flow | Parameters | Product question |
| --- | --- | --- | --- |
| login | Successful Google sign-in / 1 | method: string enum google | Is sign-in completed? |
| sign_out | Successful sign-out / 1 | none | Do users close sessions? |
| onboarding_start | Start profile / 1 | none | Is setup started? |
| profile_saved | Successful profile save / 1 | none | Is setup completed? |
| meal_entry_start | Start meal / 2 | none | Is journaling used? |
| meal_analysis_complete | Valid analysis result / 2 | none | Does analysis finish? |
| meal_saved | Successful meal write / 2 | item_count: int 0..1000 | Are results saved? |
| journal_open | Open journal / 2 | none | Is the journal revisited? |
| meal_detail_open | Open saved result / 2 | none | Are saved results read? |
| progress_open | Open progress / 3 | none | Is progress viewed? |
| lesson_catalog_open | Open catalogue / 3 | none | Is learning discovered? |
| lesson_open | Open validated lesson / 3 | none | Are lessons opened? |
| lesson_read | Explicit read status saved / 3 | item_count: int 0..1000 core units | Are lessons completed? |
| report_generated | Generate data-derived PDF | none | Are reports generated? |
| report_uploaded | Owner upload completes | none | Are reports stored? |
| report_opened | PDF viewer/share opens | none | Are reports read? |

Every event also carries flow: string enum auth/onboarding/meal/learning/report.

Status: implementation present; DebugView screenshots and ARTEMIS event assertions
remain pending live-device verification. Enable DebugView with
`adb shell setprop debug.firebase.analytics.app vn.edu.fpt.vetalife`, complete
each action and capture Firebase DebugView. Disable with
`adb shell setprop debug.firebase.analytics.app .none.`.
