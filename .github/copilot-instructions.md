# Copilot Instructions for Endurain mobile app

## Tech Stack
- **Flutter**: 3.50+ (stable channel; CI pins 3.50.1)
- **Dart**: 3.14.0+
- **Platforms**: Android, iOS, plus the Wear OS (`android/wear`) and Apple Watch (`ios/EndurainWatch`) companion apps
- **State Management**: view-model controllers extending `SafeNotifier` (`lib/shared/state/safe_notifier.dart`), wired in a composition root (`AppServices`, `lib/app/modules`, `lib/app/navigation/app_screens.dart`); features receive dependencies through constructors, never through `AppScope`/`AppServices`
- **UI Toolkit**: `material_ui` and `cupertino_ui` packages (not the core-SDK `material.dart`/`cupertino.dart`)
- **Map Provider**: OpenStreetMap (flutter_map + latlong2)
- **Secure Storage**: flutter_secure_storage
- **Location**: geolocator (foreground) + a native Android/iOS recorder for background activity capture
- **Health**: HealthKit (iOS) / Health Connect (Android) via `health`

## Dependencies

- Prefer well-maintained open-source dependencies when they meet the product requirements.
- Proprietary or store-specific SDKs are allowed when they provide a clear product, platform, security, or operational benefit. Document the rationale and isolate platform integrations behind injectable adapters.

## Code Conventions

### Commits logic

Committing should use clear messages following [Conventional Commits](https://www.conventionalcommits.org/) format with less than 72 characters on the first line, e.g.:
- `feat: add GPX max speed parsing`
- `fix: handle multi-segment GPX distance correctly`
- `docs: update development instructions`
- `test: add regression test for GPX segment handling`

### File Naming
- Use **snake_case** for all Dart files: `map_screen.dart`, `location_service.dart`
- Feature folders: `lib/features/map/`, `lib/features/settings/`
- Core utilities: `lib/core/`
- Shared widgets: `lib/shared/`

### Dart Style
- **Always** use `const` constructors when possible for performance
- Prefer `final` over `var` for immutable variables
- Use trailing commas for better formatting
- Maximum line length: 80 characters (default Dart style)

### Widget Structure
```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Widget tree
    );
  }
}
```

### Localization Requirements
- **Never** hardcode user-facing strings
- Always use `AppLocalizations.of(context)` (or `l10n` variable)
- Example: `Text(l10n.mapTab)` instead of `Text('Map')`
- Supported languages: 30 locales including English (see `lib/core/localization/app_locales.dart`); English (`app_en.arb`) is the source/reference locale. An ARB parity guard test enforces that every locale defines the same keys.
- **Translations organized by feature** in `lib/l10n/app_en.arb` and the per-locale `app_<code>.arb` files
  - Sections: Common/Shared, Errors, Auth, Activity, Map, Settings, Health sync, Sensors, Units (see `lib/l10n/README.md`)
  - When adding translations, place them in the appropriate section
  - Include usage info in description: `"Used in: your_screen.dart"`
  - Run `flutter gen-l10n` after editing ARB files

### Icons
- **Prefer Material Icons**: Built-in with `material_ui`, no extra bundle size
  - `Icon(Icons.map)`, `Icon(Icons.settings)`, `Icon(Icons.dns)`
- Avoid Font Awesome unless specifically needed (adds bundle size)

## Architecture

### Feature-Based Structure
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── auth/                  # secure_storage_service.dart, session store
│   ├── location/              # location_service.dart
│   ├── theme/
│   └── ...                    # config, constants, diagnostics, models, network, services, utils
├── app/                       # Composition root: AppServices, modules/, navigation/, widgets/ (app_bottom_nav.dart)
├── features/
│   ├── map/
│   │   ├── screens/           # map_screen.dart
│   │   └── widgets/
│   ├── settings/
│   │   ├── controllers/
│   │   ├── repositories/
│   │   ├── screens/           # settings_screen.dart, server_settings_screen.dart
│   │   └── services/
│   └── ...                    # account_migration, activity, auth, health, sensors, watch
├── shared/                    # adaptive/, layout/, state/
└── l10n/                      # app_en.arb, app_<code>.arb, README.md
```

### Layering & naming taxonomy

Each layer has one job and a consistent name. Use these terms exactly; do not
invent synonyms (no `Manager`, `ViewModel`, `Helper`, or `DAO`).

| Layer | Folder / suffix | Responsibility |
| --- | --- | --- |
| **Screen** | `screens/`, `…Screen` | Thin view. Renders controller state and dispatches user intents. Owns dialogs/navigation/form validation only. Never calls a repository/service data method and drives it with `setState`. |
| **Controller** | `controllers/`, `…Controller` (extends `SafeNotifier`) | View-model. Holds view state and policy decisions; delegates data work to services/repositories. |
| **Service** | `services/` or `core/services/`, `…Service` | Business logic, coordination, and platform integration. Platform integrations sit behind an injectable adapter interface with an `Unsupported…` fallback. |
| **Repository** | `repositories/`, `…Repository` | The public data-access **facade** a feature depends on. Composes one or more stores/services and returns domain models. |
| **Store** | `repositories/`, `…Store` | The concrete **persistence implementation** behind a repository (e.g. `SqfliteActivityStore`, `SqfliteHealthImportStore`; `FileActiveActivityStore` is a test helper in `test/helpers`, because the native recorders own the active-session files in production). Injectable so tests swap in-memory/FFI backends. |
| **Model** | `models/` | Immutable value type: `final` fields, `const` constructor where possible, `copyWith` for stateful ones. |

Rules:
- **Repository vs Store**: the *Repository* is the swappable public seam; the
  *Store* is its persistence backend. Add a Store only when there is real
  persistence to isolate — features with no database (e.g. `map`, `sensors`,
  `settings`) expose only a Repository. When both exist, the repository owns
  the store and no other layer touches the store directly.
- **Screens delegate to a Controller.** Do not read/write a repository from a
  screen with `setState`; hold a `SafeNotifier` controller instead. App-
  lifetime controllers are constructed in `AppServices`; route-owned
  controllers are built by the composition root (`lib/app/navigation/
  app_screens.dart`, `lib/app/modules`) and disposed through the
  `OwnedControllers` mixin (`lib/shared/state/owned_controllers.dart`).
- **Composition root only.** All wiring lives in `lib/app` (`AppServices`, the
  modules, `AppScreens`). Feature code receives collaborators through
  constructor parameters and never references `AppScope` or `AppServices`.

## Architecture Guards

`test/architecture/` enforces these rules in `flutter test`; read the guard
before working around it:
- `feature_service_locator_guard_test.dart`: nothing under `lib/features`
  references `AppScope` or `AppServices`.
- `app_services_instance_guard_test.dart`: `AppServices` is constructed only by
  `main.dart`, `app.dart` and `app/app_services.dart`, and `AppServices.instance`
  is never reintroduced.
- `auth_wiring_guard_test.dart`: `AuthService`, `SsoService`, `ApiClient` and
  `AuthSessionStore` are constructed only in the auth infrastructure, so there
  is a single serialized session store.
- `controller_notifier_guard_test.dart`: feature controllers extend
  `SafeNotifier`, call `notify()` instead of `notifyListeners()`, and do not
  declare their own disposal flag.
- `layering_guard_test.dart`: `lib/core` and `lib/shared` never import
  `lib/features` or `lib/app`.
- `feature_boundary_guard_test.dart`: no feature imports another feature's
  `…Store`, and stores are used only in repositories, services and the
  composition root.
- `map_activity_coupling_guard_test.dart`: the map imports only
  `activity_recording_controller.dart` and `activity_recording_overlay.dart`
  from the activity feature.
- `file_size_guard_test.dart`: source files stay under 500 lines; larger
  legacy files are capped at their current size and may only shrink.
- `design_system_migration_guard_test.dart`: use `material_ui`/`cupertino_ui`;
  the legacy core-SDK Material/Cupertino imports and the generated
  `AppLocalizations.localizationsDelegates` are not allowed (use
  `appLocalizationsDelegates`).
- `android_manifest_test.dart`: Health Connect permissions match what the app
  uses, the network security config is wired, and the private storage roots are
  excluded from Android backups.

## Dependencies Reference
`pubspec.yaml` is the authoritative list of packages and versions.

## Best Practices

### Error Handling
- Always handle location permission denial gracefully
- Validate form inputs (server URL, required fields)
- Use try-catch for async operations (storage, network)

### Performance
- Use `const` constructors to reduce widget rebuilds
- Implement `RepaintBoundary` for complex widgets if needed
- Avoid unnecessary `setState()` calls

### Security
- Never commit API keys or credentials
- Use `.gitignore` for `*.jks`, environment files (including `dart-defines.json`), and any proprietary configuration files
- Store sensitive data only in `flutter_secure_storage`

### Testing
- Write widget tests for screens
- Write unit tests for controllers, services, and repositories (inject fakes at
  the layer boundary rather than mocking the type under test)
- Test permission flows on both platforms

## Common Patterns

### Navigation
Top-level, auth-guarded routing uses `go_router` in
`lib/app/navigation/app_router.dart`: the router redirects between the splash,
login, and home destinations based on `AuthSessionController` state. Add new
top-level destinations there. Use `Navigator.push` for sub-navigation within a
destination:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ServerSettingsScreen()),
);
```

### Secure Storage
```dart
final storage = SecureStorageService();
await storage.write(key: 'server_url', value: url);
final value = await storage.read(key: 'server_url');
```

### Localization Access
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.mapTab)
```

## Git Workflow
- Commit messages and PR titles: Conventional Commits, validated by CI (e.g., `feat: add server settings form validation`)
- Branch strategy: Feature branches for major changes, named like `fix/...` or `feat/...`
- Never commit build artifacts, IDE configs, or secrets
