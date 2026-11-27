# Endurain mobile app

Mobile client for Endurain, a self-hosted fitness tracking application.
App: Flutter (`.flutter-version` is the pin), Dart 3.14+, `material_ui` and `cupertino_ui`, `go_router`, sqflite, flutter_map, flutter_secure_storage.
Native: Android phone app and Wear OS app (Kotlin, Gradle version catalog), iPhone app and Apple Watch app (Swift); iOS 17.0+, watchOS 10.0+, Android `minSdk` 26, Wear OS `minSdk` 30.
Native recorders own background activity capture; HealthKit and Health Connect through `health`.

## Where the detail lives

| Working on | Read |
| --- | --- |
| Dart code or tests (`lib/`, `test/`, `integration_test/`) | `.agents/skills/endurain-flutter/SKILL.md` |
| Kotlin or Swift code (`android/`, `ios/`) | `.agents/skills/endurain-native/SKILL.md` |
| Fixing a bug, failing test or CI failure | `.agents/skills/debugging/SKILL.md` |
| Commit messages, PRs and the changelog | `.agents/skills/conventional-commits/SKILL.md` |
| Writing or editing a skill | `.agents/skills/skill-authoring/SKILL.md` |
| Full check list, the CI jobs and what triggers them | `CONTRIBUTING.md` ("Testing and Quality Checks") |
| Builds, release signing, local storage layout, recovery contract | `README.md` |
| ARB sections and metadata | `lib/l10n/README.md` |

Skills are plain Markdown; read the relevant `SKILL.md` and the reference files it points to when your tool does not load skills itself.

## Layout

```text
lib/              Flutter app: app/ (composition root), core/, features/, shared/, l10n/
test/             Dart tests; architecture/ holds the guards, fixtures/ the vectors shared with Kotlin and Swift
integration_test/ On-device smoke tests
tool/             Coverage and dead-code checkers
android/          app/ (phone), wear/ (separate Gradle build), watch_shared/{common,watch}, gradle/libs.versions.toml
ios/              Runner/, RunnerTests/, EndurainWatch/, EndurainWatchTests/, Shared/
docker/           CI builder image
.agents/skills/   Agent skills (symlinked into .claude/skills)
```

## Commands

Dart (what the `Format`, `Analyze` and `Test` jobs run):

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
dart run tool/check_dead_code.dart
flutter test test/<area>
flutter test --coverage && .github/scripts/check_coverage.sh
flutter gen-l10n            # after ARB changes
```

Android, Wear OS, iOS and watchOS commands are in the `endurain-native` skill.

## Rules for every change

- Do only what was asked; no extra docs, summaries, READMEs or "helpful" files.
- Prefer existing patterns, utilities and files over new ones.
- KISS: pick the simplest design that solves the underlying problem; no indirection, abstraction layer or option without a current need. Simple means few moving parts, not a small diff or a patch over the symptom.
- YAGNI: build only what the task needs now; no speculative parameters, flags, hooks, config or extension points. What you do build must be complete and proper, not a stub or shortcut.
- DRY: reuse an existing helper, adapter, model or adaptive primitive before writing another; extract shared code at the second repetition, and only when the copies change for the same reason.
- Do not change CI workflows, the CI builder image, signing configuration, application or bundle identifiers, permissions, entitlements, or the Flutter, Dart, Gradle, Kotlin or Xcode versions unless asked.
- Never run `git commit` (or any commit-creating command) unless the user explicitly asks; staging for inspection is fine.
- Commit messages and PR titles follow Conventional Commits (enforced in CI); see the `conventional-commits` skill.
- Local-only notes go in `devdocs/` (gitignored).
- No hardcoded secrets, keys or server URLs; signing secrets stay in the ignored `android/key.properties` or CI variables, and build-time values come from `--dart-define-from-file` (`dart-defines.json`, ignored).
- Ask for clarification when scope is unclear instead of assuming extra deliverables.
- A change touching more than one feature, or both Dart and native code, starts with a short task list in chat for approval; keep plans in chat or `devdocs/`, never in tracked files.
- Bug fixes and new behavior start with a failing test.
- A user-visible change adds an entry under `## [Unreleased]` in `CHANGELOG.md`, in the matching Keep a Changelog section.
- Done means the checks that apply to what changed ran and their output was read; say which ran and which did not (checks do not apply to docs, `AGENTS.md` or skill-only changes). Name the platforms you could not build or test locally.
- Before reporting a larger change done, compare the diff to the request and remove anything not asked for.

## Fixing problems

- Fix the root cause, not the symptom. Before changing code, state the cause you found and the evidence for it.
- Do not add workarounds: no special-case branches, swallowed exceptions, retries, delays or extra `pump`s to hide a failure, `// ignore:` comments, test skips or loosened assertions, or defensive checks that mask bad state upstream.
- If the proper fix is larger than the request (touches other features, changes a boundary, needs native changes or a refactor), stop and ask before editing. Present the options:
  1. Proper fix: what it changes and why it is the right one.
  2. Minimal fix: what it leaves broken or the debt it creates.

  Recommend one. Never apply the minimal option without the user's choice.
- If unsure whether a fix is a workaround, treat it as one and ask.

## Building features

- Build the feature the way the architecture intends: correct feature folder, layer and boundaries per the `endurain-flutter` skill, even when a shortcut would be quicker.
- Do not take shortcuts: no placeholder or stubbed logic, hardcoded values or strings, TODOs standing in for required behavior, copy-pasted code instead of reuse, logic in the wrong layer, or skipped tests, error handling, translations, schema migrations or the native side of a platform feature.
- Before writing code, state the approach and the files it touches. If more than one reasonable design exists, or the proper design is larger than the request implies, stop and ask. Present the options:
  1. Proper design: what it involves and why it fits the architecture.
  2. Simpler design: what it cuts or defers, and the debt it creates.

  Recommend one. Never apply the simpler option without the user's choice.
- Scope still applies: complete means done properly, not bigger. Do not add features, options or files that were not requested.

## App invariants

- Feature code lives in `lib/features/<feature>/`, layered Screen, Controller, Service, Repository, Store, Model; no `Manager`, `ViewModel`, `Helper` or `DAO`.
- All wiring lives in the composition root (`lib/app`); feature code takes collaborators through constructors and never references `AppScope` or `AppServices`.
- Controllers extend `SafeNotifier` and call `notify()`, never `notifyListeners()`.
- `lib/core` and `lib/shared` never import `lib/features` or `lib/app`; a feature never imports another feature's `…Store`.
- UI imports `material_ui` and `cupertino_ui`, never the core-SDK `material.dart` or `cupertino.dart`.
- Every user-facing string goes through `AppLocalizations`, in all 30 locales; text the OS shows outside Flutter goes in the native resources.
- Plugin calls sit behind an injectable adapter before a controller or screen sees them.
- Failures become `AppException` with an `AppErrorCode`; services stay language-free and the UI localizes the error.
- Tokens and session state go only through the auth session store; secrets only in `flutter_secure_storage`.
- Source files stay under 500 lines; a public declaration in `lib/` is referenced from `lib/` or is a `@visibleForTesting` seam.
- `test/architecture/` and `tool/check_dead_code.dart` enforce these; read the guard before working around it, and never widen an allowlist or cap to pass.
- Comments and doc comments state what the code does now and why; history goes in the commit message.

## Native invariants

- The method-channel contract is mirrored in Dart, Kotlin and Swift; a payload change ships on all three together, with `payloadVersion` bumped.
- Logic implemented on more than one platform is pinned by the shared vectors in `test/fixtures/`; Dart, Kotlin and Swift tests all read them.
- Permission declarations match what the app does; request and describe background location only as the native recorder uses it.
- File, database and sensor work runs off the main thread.
