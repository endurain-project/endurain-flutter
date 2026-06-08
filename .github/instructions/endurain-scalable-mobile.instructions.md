---
description: "Use when changing Endurain Flutter features, architecture, adaptive UI, localization, tests, platform integrations, security, release configuration, or mobile best practices. Preserves the scaling rationale from the refactors."
name: "Endurain Scalable Mobile Guidelines"
applyTo: "lib/**, test/**, android/**, ios/**, macos/**, pubspec.yaml, l10n.yaml, analysis_options.yaml"
---
# Endurain Scalable Mobile Guidelines

## Architecture

- Keep feature code under `lib/features/<feature_name>/`.
- Screens render UI and forward user intent; they should not own complex workflow orchestration.
- Controllers own workflow state, loading state, stream lifecycles, and async transitions.
- Repositories coordinate feature data and return typed models or typed results.
- Services isolate HTTP, secure storage, auth/session behavior, and platform APIs.
- Wire shared dependencies through `AppServices`, `AppScope`, and constructor injection instead of creating new service instances inside widgets.
- Add abstractions only when they remove real duplication or protect a boundary that is already repeated.

## State Management and Dependency Injection

**Decision (2026-06-08):** Keep `ChangeNotifier` + `AppScope` `InheritedWidget` +
`AppServices` global singleton. Do **not** migrate to Riverpod or Provider until
there is a concrete multi-account or multi-environment requirement that the
current approach cannot satisfy.

**When to create each layer:**
- **Service** — when the unit isolates exactly one platform API, one HTTP
  endpoint family, or one storage concern. Services must be constructable with
  mock/fake collaborators in unit tests.
- **Repository** — when a feature needs to compose two or more services, own
  domain caching, or return a typed result that hides storage keys from the
  caller. Repositories are feature-local unless the same composition is needed
  in two features.
- **Controller** (`ChangeNotifier`) — one per screen/route that owns mutable UI
  state, loading flags, stream subscriptions, and async transitions. Dispose
  streams and subscriptions in `dispose()`.
- **Long-lived controller** — hoist to `AppServices` (not the screen) when the
  controller must survive tab navigation or be shared across screens. The active
  recording controller is the canonical example.

**DI rules:**
- Inject collaborators through constructors. Default parameters use `??
  Collaborator()` so tests can supply fakes without a service locator.
- Screens and controllers obtain shared services via
  `AppScope.servicesOf(context, listen: false)`, never by calling
  `AppServices.instance` directly inside widget code.
- `AppConfig` (in `AppServices.config`) is the single home for build-time
  environment knobs (API base path, transport policy, feature flags). Add new
  flags there; do not scatter `const bool kFeatureX = true` across files.

## API, Auth, And Security

- Use typed `ApiClient` helpers and `ApiResponse` parsing instead of passing raw HTTP responses into features.
- Map failures to `AppException` and `AppErrorCode`; localize user-facing errors at the UI boundary.
- Keep token/session persistence centralized through the auth session store path.
- On refresh failure, clear the auth session consistently.
- Never store raw passwords or secrets in the repo.
- Keep Android signing secrets in ignored `android/key.properties` or CI environment variables.
- Preserve F-Droid compatibility: do not add Firebase, Google Maps, Google Play Services, or proprietary SDK dependencies.

## Localization

- Never hardcode user-facing strings in widgets, dialogs, validators, snack bars, errors, or button labels.
- Add English and Portuguese ARB entries together.
- Include ARB metadata descriptions with usage context such as `Used in: activity_screen.dart`.
- Keep service-layer errors language-free and map them to localized text near the UI.
- Run `flutter gen-l10n` after ARB changes when generated files need refreshing.

## Adaptive UI

- Use shared adaptive primitives from `lib/shared/adaptive/` before adding platform branches.
- Android should render through Flutter Material or Material 3 widgets.
- iOS and macOS should render through Flutter Cupertino widgets where supported.
- Do not hand-roll platform visual effects, custom glass/blur surfaces, or platform-lookalike widgets when native Flutter families do not expose that behavior.
- Add a new adaptive primitive only when the pattern repeats across features.

## Platform And Mobile Best Practices

- Put plugin calls behind injectable adapters before they appear in controllers or screens.
- Handle permissions, denial states, unavailable services, and platform exceptions gracefully.
- Keep permission declarations aligned with actual behavior. Do not request or describe background location until background activity tracking exists.
- Keep release identifiers production-looking and consistent across Android, iOS, and macOS.
- Do not sign Android release builds with debug keys.

## Testing And Validation

- Add tests at the layer where behavior lives: model parsing, repository/service contracts, controller state transitions, and important widget states.
- Use fake adapters instead of live platform channels in unit and controller tests.
- For new features, include focused tests for success, failure, loading, and cleanup paths.
- Before finishing meaningful changes, run `flutter analyze` and relevant tests.
- Run platform builds when platform config changes and the local SDKs are available.

## Documentation

- Document new architecture patterns, adapter contracts, route conventions, release steps, and test helpers in a comment or README adjacent to where the code lives, or update this instruction file directly.
