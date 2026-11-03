# Implementation AI log

This records actual assistance, not the later required AI pull-request review.
Supporting source: From Design section 9 / Appendix A, which asks for six entries
over implementation. Do not fabricate entries before work occurs.

## SETUP-01 - Folder scaffold (2026-11-03)

- Tool: Codex with specialized Flutter and QA agents.
- User prompt, verbatim:

> để bạn có thể hiểu được rõ cấu trúc mà tôi muốn implement bạn hãy đọc toàn bộ các file pdf trong requirements, nó có chứa các yêu câu của bài lab3, trước mắt tôi cần bạn khởi tạo folder structure cho đúng với yêu cầu trước khi thực hiện bài lab, không cần commit requirements lên gh

- Output: full reading/comparison of four PDFs (69 pages), folder structure,
  document templates, evidence locations, and ignore rules. No app features.
- Decision: user confirmed ARTEMIS / Cloud-Enabled + Preparation Guide v5.
  MobAI and Final Assignment conflicts are documented separately.
- Verification: final scaffold checks in `docs/lab3-requirements.md`.

## Future entries

| ID/date | Tool | Verbatim prompt or saved path | Output | Actual verification | Decision/reason | Files/commit |
| --- | --- | --- | --- | --- | --- | --- |
