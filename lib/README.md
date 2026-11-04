# Flutter source structure

Flows 1 and 2 are implemented. `main.dart` starts `VetaLifeApp`; default preview mode uses
local data. Cloud adapters and Firebase client configuration are implemented;
cloud behavior remains unverified.

| Folder | Responsibility |
| --- | --- |
| `models/` | Plain Dart data types and serialization; no UI or service calls. |
| `services/` | Firebase, external API, file export, and other external operations. |
| `firebase/` | Firebase-specific initialization and SDK configuration helpers used by services. |
| `viewmodels/` | Screen state, business logic, and calls to injected services. |
| `screens/` | Screens that render ViewModel state and forward user actions. |
| `widgets/` | Reusable components and their states from the Lab 2 component library. |
| `theme/` | Lab 2 design tokens, `ThemeData`, typography, spacing, and radius constants. |
| `utils/` | Small shared helpers that do not depend on screens or ViewModels. |

Provider 6.1.5+1 is used consistently. Widgets delegate state and external operations
to ViewModels/services. Data-loading state and recoverable failures belong to the ViewModels.

The VetaLife Android app is registered in project `vetalife-24f03`. Complete
Google Sign-In and rules verification before cloud use. See [architecture](../docs/architecture.md) and
[Firebase setup](../docs/firebase-setup.md). Flow 2 uses `MealViewModel`,
`MealFlowScreen` and injected meal repositories/intelligence adapters.
`AiLogicMealIntelligence` uses the `firebase_ai` SDK with the Gemini Developer
API backend. [Its setup guide](../docs/flow2-setup.md) describes the Spark console
setup and App Check; this path requires neither a Gemini key in Flutter nor
Functions deployment. Source references and minimal profile metadata are
prepared/validated in the client. The old `functions/` backend is optional legacy.
AI Logic provider activation and service App Check enforcement are confirmed
for the Android/web apps. Token exchange and a non-personal model connectivity
check returned HTTP 200, with the temporary token revoked afterward. Runtime
App Check registration and real-meal/native-camera validation remain. No billing
plan change was made.
Flow 3 remains pending.
