# Testing

Tests live in `test/` mirroring `lib/`; files are `*_test.dart`.
A test asserts an outcome (state the controller exposes, rows read back, widgets on screen, the request sent to a fake server), never the calls the code made to its own collaborators.

## Pick the test by what it proves

| The test proves | Write |
| --- | --- |
| A model, parser or pure function | Unit test, no fakes |
| A repository or store against real SQL | Unit test on `sqflite_common_ffi` |
| A controller's state transitions, loading, failure and cleanup | Unit test with fakes at the service or repository boundary |
| A screen's states and intents | Widget test through `test/helpers/widget_test_app.dart` |
| Logic shared with Kotlin or Swift | A vector in `test/fixtures/*.json`, read by the Dart, Kotlin and Swift tests |
| A flow on a device (recording, navigation shell) | `integration_test/` |
| An architecture rule | A guard in `test/architecture/` |

## Writing them

- Fakes live in `test/helpers/` (`fake_*`, `in_memory_*`); reuse one before writing another, and add a new one there when two tests need it.
- Fake at the layer boundary; never fake the type under test or a live platform channel in a unit test.
- Cover success, failure, loading, empty, denied-permission and cleanup paths, not only the happy path.
- Control time through the injected `DateTime Function()` (or `fake_async` for timers); never wait on real time, and do not add `pump` calls or durations to get a race to pass.
- Dispose controllers and close streams the test created; a leak fails later tests.
- Tests are order-independent: no shared mutable top-level state.
- Never skip, loosen or delete a test to get green.

## Gates

- Coverage: `flutter test --coverage && .github/scripts/check_coverage.sh` fails under 80% overall or 60% per file.
- `.github/coverage-excludes.txt` lists the excluded globs with a reason each; prefer a test over a new exclusion, and never exclude logic.
- Dead code: `dart run tool/check_dead_code.dart` fails when a public declaration in `lib/` is referenced only from tests.
  Delete it, make it private, or mark a deliberate test seam `@visibleForTesting`; `.github/dead-code-allowlist.txt` is for cross-language contracts and needs a reason.
- A stale allowlist entry also fails the check; remove it with the declaration.

## Commands

```bash
flutter test test/features/<feature>          # one area
flutter test test/architecture                # the guards
flutter test --coverage && .github/scripts/check_coverage.sh
flutter test integration_test                 # needs a running emulator or simulator
```
