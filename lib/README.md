# Flutter source structure

Flow 1 is implemented. `main.dart` starts `NepLanhApp`; default preview mode uses
local data. Cloud adapters are implemented and await Firebase project setup.

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

Replace the explicit Firebase setup stub using `flutterfire configure` after
creating your project. See [architecture](../docs/architecture.md) and
[Firebase setup](../docs/firebase-setup.md). Flows 2/3 remain pending.
