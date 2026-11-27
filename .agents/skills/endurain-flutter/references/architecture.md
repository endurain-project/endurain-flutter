# Architecture

## Layers

| Layer | Folder / suffix | Job |
| --- | --- | --- |
| Screen | `screens/`, `…Screen` | Renders controller state and dispatches intents; owns dialogs, navigation and form validation only. |
| Controller | `controllers/`, `…Controller` (extends `SafeNotifier`) | One per screen or route with mutable state: view state, loading flags, stream subscriptions, async transitions and policy decisions. |
| Service | `services/` or `lib/core/services/`, `…Service` | Isolates one platform API, one HTTP endpoint family or one storage concern; constructible with fakes. |
| Repository | `repositories/`, `…Repository` | The feature's public data facade: composes services and stores and returns domain models or typed results. |
| Store | `repositories/`, `…Store` | The persistence backend behind a repository (`SqfliteActivityStore`, `SqfliteHealthImportStore`); injectable so tests swap in FFI or in-memory backends. |
| Model | `models/` | Immutable value: `final` fields, `const` constructor where possible, `copyWith` for stateful ones. |

- Add a store only when there is real persistence to isolate; features without a database (`sensors`, `settings`) expose only a repository.
- When both exist, the repository owns the store and no other layer touches it.
- A repository is feature-local until a second feature needs the same composition; then it moves to `lib/core` (as `MapSettingsRepository` did, read by the map and the activity feature).
- Hoist a controller to `AppServices` only when it must survive tab navigation or be shared across screens (the active recording controller).
- Add an abstraction only when it removes real duplication or protects a boundary that already repeats.

## Composition root

- `lib/app` holds all wiring: `AppServices`, `modules/`, `navigation/app_screens.dart` and `navigation/app_router.dart`.
- `AppServices` is constructed only by `main.dart`, `app.dart` and `app/app_services.dart`; there is no `AppServices.instance`.
- `AuthService`, `SsoService`, `ApiClient` and `AuthSessionStore` are constructed only in the auth infrastructure, so there is one serialized session store.
- Top-level, auth-guarded destinations are `go_router` routes in `app_router.dart`, redirected on `AuthSessionController` state; sub-navigation inside a destination uses `Navigator.push`.

## Feature coupling

- `lib/features/auth` and `lib/features/activity` never import `lib/features/map` (the map imports activity).
- The map imports only `activity_recording_controller.dart` and `activity_recording_overlay.dart` from activity.
- `lib/features/settings` imports no activity code and only the listed health entry points.
- A new cross-feature need goes through `lib/core`, `lib/shared` or a constructor parameter wired in `lib/app`, never a new import edge between features.

## Guards

| Guard (`test/architecture/`) | Fails when |
| --- | --- |
| `feature_service_locator_guard_test.dart` | `lib/features` references `AppScope` or `AppServices` |
| `app_services_instance_guard_test.dart` | `AppServices` is constructed outside the composition root |
| `auth_wiring_guard_test.dart` | an auth session service is constructed outside the auth infrastructure |
| `controller_notifier_guard_test.dart` | a controller skips `SafeNotifier`, calls `notifyListeners()` or keeps its own disposal flag |
| `layering_guard_test.dart` | `lib/core` or `lib/shared` imports `lib/features` or `lib/app` |
| `feature_boundary_guard_test.dart` | a feature imports another feature's store, or a store is used outside repositories, services and the root |
| `feature_coupling_guard_test.dart`, `map_activity_coupling_guard_test.dart` | a feature import edge above is crossed |
| `file_size_guard_test.dart` | a Dart, Kotlin or Swift source reaches 500 lines, or a capped legacy file grows |
| `design_system_migration_guard_test.dart` | core-SDK Material or Cupertino is imported, or the generated `localizationsDelegates` is used |
| `android_manifest_test.dart` | Health Connect permissions, the network security config or backup exclusions drift |

A file over the size limit is split by responsibility, not trimmed by squeezing lines; a cap only shrinks.

## Local storage

- Activity metadata is in `activity.db`, health import provenance in `health_import.db`; GPX tracks stay as files (layout in `README.md`, "Local Activity Storage Design").
- Schema changes append a migration to the ordered map and bump the schema version; never edit a shipped migration.
- Fresh installs and upgrades run the same migration steps (`lib/core/utils/sqlite_migration_runner.dart`).
- Write files atomically: write a staging file, then rename it over the target (as `local_activity_gpx_storage.dart` does), so an interrupted write cannot leave a truncated file.
- The native recorders own the active-session files; Dart recovery attaches to them and follows the recovery contract in `README.md`.
