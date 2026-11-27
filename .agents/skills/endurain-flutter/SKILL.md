---
name: endurain-flutter
description: Endurain Flutter app conventions (layering, composition root, SafeNotifier, adaptive UI, l10n). Use when adding, changing or reviewing code in lib/, test/ or integration_test/.
---

# Endurain Flutter app

Repo-wide rules and the app invariants are in `AGENTS.md`; this skill adds what applies to every Dart change.
The guards in `test/architecture/` are authoritative; where this skill and a guard disagree, the guard wins.

## Core rules (always apply)

- A file's folder and suffix are its layer (`screens/…Screen`, `controllers/…Controller`, `services/…Service`, `repositories/…Repository` or `…Store`, `models/`); name it for what it does.
- A screen renders controller state and forwards user intent; it never drives a repository or service with `setState`.
- New dependencies are constructor parameters; a default uses `?? Collaborator()` so tests pass a fake without a service locator.
- No Riverpod, Provider, BLoC or `get_it`; state is a `SafeNotifier` controller wired in `lib/app`.
- A route-owned controller is built in `lib/app/navigation/app_screens.dart` or `lib/app/modules` and disposed through `OwnedControllers`; an app-lifetime controller lives in `AppServices`.
- A build-time knob (endpoint path, transport policy, feature flag) goes in `AppConfig`, not a scattered `const bool`.
- Cancel every subscription and close every sink in `dispose()` (`cancel_subscriptions`, `close_sinks`); check `isDisposed` after an `await` before touching state.
- `flutter analyze` must report nothing: strict casts, inference and raw types are on; fix the type, never add `// ignore:`.
- Package imports only (`package:endurain/...`); `dart format` decides layout and trailing commas.
- Public declarations get a `///` doc comment that says what, then why when not obvious; reference other symbols with `[Name]` (`comment_references`).
- KISS, YAGNI, DRY: search `lib/core`, `lib/shared` and the feature for an existing helper, adapter or adaptive primitive first; add no parameter, interface or layer without a current caller.

## Read on demand

| When you are | Read |
| --- | --- |
| Adding a feature, controller, service, repository, store, route or schema migration | `references/architecture.md` |
| Building UI, adding text or a locale | `references/ui-and-l10n.md` |
| Calling the server, handling auth or errors, wrapping a plugin, adding a permission or dependency | `references/platform-and-security.md` |
| Writing or fixing tests, coverage or dead-code failures | `references/testing.md` |

## Before finishing

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
dart run tool/check_dead_code.dart
flutter test --coverage && .github/scripts/check_coverage.sh
```

A change under `lib/` can break the native builds and the iOS workflow; if it touches a channel, a plugin or shared logic, also use the `endurain-native` skill.

## Repo hygiene

- Commit messages, PRs and the changelog: use the `conventional-commits` skill.
- Never run `git commit` unless asked.
