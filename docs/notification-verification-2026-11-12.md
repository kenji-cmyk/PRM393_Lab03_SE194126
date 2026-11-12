# Android push verification — 2026-11-12

Target: the connected CPH2799 Android phone, active cloud app on
`vetalife-24f03`. User explicitly requested a real push delivery test.

Notification permission was granted and exactly one Android registration was
present for the selected account. Three bounded, generic test messages were
sent to that registration; no personal profile or meal data was included and
the FCM registration token was not printed.

| State | FCM | Android/device evidence |
| --- | --- | --- |
| App in background | HTTP 200 | Matching OS notification record and persisted app history |
| App process stopped | HTTP 200 | Process confirmed stopped before send; matching OS notification record and persisted history |
| App brought to foreground | HTTP 200 | App window focused before send; matching message persisted in history; OS notification record also observed |

The stopped-process test used a process termination, not Android force-stop.
Delivery after force-stop is not claimed. Tests did not clear notification
permission or change the user's notification settings.

The observed channel was `fcm_fallback_notification_channel`, importance 3.
System tray delivery is confirmed for background/stopped-process states. Heads-up
banner appearance and tap routing were not verified. Source implements an
in-app snackbar for foreground receipt, but foreground-only presentation was
not visually confirmed: UI automation could not obtain an idle hierarchy, and
an OS notification record was also observed in that test.

Sanitized evidence: `evidence/cloud/fcm-device-verification-2026-11-12.json`.
