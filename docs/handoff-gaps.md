# Handoff gaps

The supplied Figma file has now been inspected. Its brand, persona, screens,
flows, tokens, and components are summarized in [the design specification](../design/DESIGN.md)
and [the reconstructed handoff](../handoff/flutter-handoff.md).
This record separates recovered design facts from unresolved implementation contracts.

| ID | Gap | Current resolution / next step | Status |
| --- | --- | --- | --- |
| HG-01 | Approved Lab 2 design/handoff was absent from the scaffold | User supplied Figma; existing screens/flows/tokens inspected and documented. Confirm any separate original Lab 2 written deliverables before implementation. | Figma baseline recovered; original written handoff confirmation pending |
| HG-02 | Flow 1 had no personal-information screen | Profile now implemented with real validation, editable date/picker, derived age and persisted goal | Local flow verified; cloud runtime awaits project |
| HG-03 | Generic micro-lesson did not follow the chosen book | Exact hierarchy mapped in `book-curriculum.md`; two catalogue views and shared selected-title/source reader created in Figma | Design amendment complete; static selection wiring/screenshots reviewed; full lesson editorial work pending and mark-read remains prototype feedback only |
| HG-04 | Real cloud project not configured | User will create Firebase later; Google Auth and users/{uid} adapter/rules implemented; setup in firebase-setup.md | Cloud verification open; meal/progress contracts deferred |
| HG-05 | State/dependency versions not selected | Provider 6.1.5+1 selected; direct dependencies and lockfile pinned | Resolved for flow 1 |
| HG-06 | No runnable app/tests | Flutter root initialized; flow 1, local tests, browser preview and debug APK verified | Flow 1 resolved; ARTEMIS/flows 2/3 open |

Profile schema fields in the handoff are proposed contracts, not deployed
Firebase collections or API endpoints. Keep personal profile values out of
Analytics parameters.
