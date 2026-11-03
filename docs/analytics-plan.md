# Analytics plan

Status: template; no tracking implemented or events verified.
Source: Cloud-Enabled section 6 / Appendix A; Preparation Guide v5 pp.14-16.
Complete this plan **before** writing tracking code.

Plan at least seven events covering sign-in, sign-out, the primary action/search,
each kind of detail screen, and file generation/upload. Use recommended event
names when applicable; snake_case otherwise. Map each to actual Lab 2 flow steps
and product questions. Set user ID after sign-in; no personal data in parameters.

| Event | Trigger | Parameters/types | Product question | Lab 2 flow step | Service/ViewModel | DebugView evidence | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |

Keep real per-event screenshots in `evidence/debugview/`. At least one ARTEMIS
scenario must also verify that its analytics event was logged.
