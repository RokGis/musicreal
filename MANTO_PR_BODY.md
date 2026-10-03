## LD1 — Mantas: automated tests for SCRUM-30, 33, 62 and 65

**Testing only — no production code is changed.** The changes are automated tests and test doubles under `test/mantas/`, plus Markdown documentation (`MANTO_*.md`).

### What is tested
- SCRUM-62 / SCRUM-65 — choosing one emoji (emotion) for the uploaded song
- SCRUM-30 / SCRUM-33 — registration, sign-in and profile through Google and Meta/Facebook only

### Results (`flutter test test/mantas/ -r expanded`, Flutter 3.44.9, identical on two runs)
- **38 automated tests: 29 PASS / 9 FAIL / 0 BLOCKED**
- Jira TC: 22/22 executed — 18 PASS, 4 FAIL (TC-FEAT62-03, TC-US65-01, TC-FEAT30-02, TC-US33-04)
- Acceptance criteria: **21/21 covered (100 %)** — 17 PASS, 4 FAIL
- Error-based tests included (`EBT-POST-*`, `EBT-AUTH-*`)

### The 9 failing tests are intentional
They document quality problems found by testing; **the defects are intentionally not fixed in this PR**:
- 4 defect groups confirmed by 8 failing requirement/AC tests:
  - D1 — 3 emojis instead of the required 5
  - D2 — Facebook cancel/failure (Android/iOS path): null crash, required message missing
  - D3 — Google cancel (Android/iOS path): required message missing
  - D4 — Google SDK `PlatformException` not handled
- 1 requirement gap (G1, `EBT-POST-07`): behaviour after a failed upload is not defined in Jira — not an AC violation

Requirement/testability gaps (G1–G6, e.g. TC-FEAT30-06 asking for a visible uid that its AC does not require) are reported separately from implementation defects and are not counted as product bugs.

### Notes
- Firestore, Firebase Auth, Google Sign-In and Facebook Login are replaced by test doubles at the platform-interface layer; no real OAuth or network access.
- The legacy `test/widget_test.dart` already fails on `main` (Firebase not initialised). It is unchanged and **excluded from Mantas's totals**.
- Full report: `test/mantas/MANTO_4_UZDUOTIS_FINAL.md`; defect summary `MANTO_DEFECTS.md`; Jira results `MANTO_JIRA_RESULTS.md`; screenshot guide `MANTO_SCREENSHOTS.md`. Screenshots themselves are not yet collected and are not part of this PR.

**DO NOT MERGE until the team agrees** — the failing tests are evidence for the LD1 assignment.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
