# Flutter tests

- `unit/`: profile/date models, onboarding/auth ViewModels and local persistence with injected fakes.
- `widget/`: flow 1 rendering, form input, back/retry/saving and narrow/large-text layouts.
- `widget_test.dart`: cloud configuration failure and sign-out recovery from profile-load error.

Run `flutter test`. Flow 1 currently has 39 passing unit/widget tests; see
[the test report](../docs/test-report.md). Service fakes test local logic, not
Firebase integration. Android E2E scenarios use ARTEMIS and remain pending in
`../e2e_test/`.
