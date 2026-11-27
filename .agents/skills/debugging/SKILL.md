---
name: debugging
description: Root-cause workflow for bugs, failing tests and CI failures. Use before changing code to fix unexpected behavior.
---

# Debugging

## Order of work

1. Reproduce the failure with a command or a test; if you cannot reproduce it, say so instead of guessing.
2. Read the full error and trace it to the first wrong value or call, not the line that raised.
3. State the cause in one sentence and confirm it with evidence (a log, a failing assertion, a minimal call).
4. For a behavior bug, write a failing test that captures it (`endurain-flutter` `references/testing.md`; Kotlin or Swift tests per `endurain-native`); for a lint, analyzer, build or environment failure, the original failing command is the check.
5. Fix the cause with the smallest change; do not patch the symptom or widen the change.
6. Run the new test, then the area's tests, then the checks listed in the matching skill.

## Rules

- Change one thing at a time; revert an attempt that did not help before trying the next.
- After two failed fixes, stop and re-read the evidence; the diagnosis is probably wrong.
- Never skip, loosen or delete a test to get green.
- A bug in logic that also runs natively is fixed on every platform that has it, with a shared vector in `test/fixtures/` that failed before.
- Reproduce a CI failure locally with the job's command when feasible; if runner-specific conditions block that (Xcode or simulator version, emulator, macOS runner), record the CI evidence and verify the fix in CI.
- A field report or crash may need a real device (background location, HealthKit, Health Connect, BLE); say which device and OS the fix was verified on, or that it was not.
- Report what was verified and what was not; do not say "fixed" without a passing run.
