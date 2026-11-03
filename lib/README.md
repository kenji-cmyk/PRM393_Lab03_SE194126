# Flutter source structure

This is a folder scaffold for Lab 3. The app and Firebase integration are not implemented yet.

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

Choose either Provider or Riverpod during implementation and use it consistently. Widgets must not call Firebase or external APIs directly. Data-loading screens will expose loading, data, empty, and error states through their ViewModels.

Create `main.dart`, generate the real Firebase configuration, and initialize the Android Flutter project when implementation starts. No placeholder Firebase project identifiers or feature screens are supplied here. See [architecture](../docs/architecture.md) for the planned dependency rules and source requirements.
