# Copilot Instructions for Endurain mobile app

## Tech Stack
- **Flutter**: 3.47+ (stable channel; CI pins 3.47.1)
- **Dart**: 3.12+
- **Platforms**: Android, iOS
- **State Management**: `ChangeNotifier` view-model controllers wired in a composition root (`AppServices`) and exposed via `AppScope`; obtain services with `AppScope.servicesOf(context)`
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
- Supported languages: 30+ locales (see `lib/core/localization/app_locales.dart`); English (`app_en.arb`) is the source/reference locale. An ARB parity guard test enforces that every locale defines the same keys.
- **Translations organized by feature** in `lib/l10n/app_en.arb` and the per-locale `app_<code>.arb` files
  - Sections: Common/Shared, Auth, Map, Activity, Health, Settings (see `lib/l10n/README.md`)
  - When adding translations, place them in the appropriate section
  - Include usage info in description: `"Used in: your_screen.dart"`
  - Run `flutter gen-l10n` after editing ARB files

### Icons
- **Prefer Material Icons**: Built-in, no extra bundle size
  - `Icon(Icons.map)`, `Icon(Icons.settings)`, `Icon(Icons.dns)`
- Avoid Font Awesome unless specifically needed (adds bundle size)

## Architecture

### Feature-Based Structure
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/
│   │   └── app_theme.dart
│   └── services/
│       ├── secure_storage_service.dart
│       └── location_service.dart
├── features/
│   ├── map/
│   │   ├── map_screen.dart
│   │   └── widgets/
│   └── settings/
│       ├── settings_screen.dart
│       ├── server_settings_screen.dart
│       └── widgets/
├── shared/
│   └── widgets/
│       └── app_bottom_nav.dart
└── l10n/
    ├── app_en.arb
    └── app_pt.arb
```

### Layering & naming taxonomy

Each layer has one job and a consistent name. Use these terms exactly; do not
invent synonyms (no `Manager`, `ViewModel`, `Helper`, or `DAO`).

| Layer | Folder / suffix | Responsibility |
| --- | --- | --- |
| **Screen** | `screens/`, `…Screen` | Thin view. Renders controller state and dispatches user intents. Owns dialogs/navigation/form validation only. Never calls a repository/service data method and drives it with `setState`. |
| **Controller** | `controllers/`, `…Controller` (extends `ChangeNotifier`) | View-model. Holds view state and policy decisions; delegates data work to services/repositories. |
| **Service** | `services/` or `core/services/`, `…Service` | Business logic, coordination, and platform integration. Platform integrations sit behind an injectable adapter interface with an `Unsupported…` fallback. |
| **Repository** | `repositories/`, `…Repository` | The public data-access **facade** a feature depends on. Composes one or more stores/services and returns domain models. |
| **Store** | `repositories/`, `…Store` | The concrete **persistence implementation** behind a repository (e.g. `SqfliteActivityStore`, `FileActiveActivityStore`, `SqfliteHealthImportStore`). Injectable so tests swap in-memory/FFI backends. |
| **Model** | `models/` | Immutable value type: `final` fields, `const` constructor where possible, `copyWith` for stateful ones. |

Rules:
- **Repository vs Store**: the *Repository* is the swappable public seam; the
  *Store* is its persistence backend. Add a Store only when there is real
  persistence to isolate — features with no database (e.g. `map`, `sensors`,
  `settings`) expose only a Repository. When both exist, the repository owns
  the store and no other layer touches the store directly.
- **Screens delegate to a Controller.** Do not read/write a repository from a
  screen with `setState`; hold a `ChangeNotifier` controller instead. App-
  lifetime controllers are constructed in `AppServices`; route-owned
  controllers are built via an `AppServices.createXController()` factory (or
  from an injected test seam) and disposed through the `OwnedControllers`
  mixin (`lib/shared/state/owned_controllers.dart`).
- **Composition root only.** All wiring lives in `AppServices`; obtain services
  via `AppScope.servicesOf(context)`. Never reference `AppServices.instance`
  from feature code — this is enforced by
  `test/architecture/app_services_instance_guard_test.dart`.

## Package Versions (Reference)
The authoritative list is `pubspec.yaml`; keep this section in sync when adding load-bearing dependencies:
- `cupertino_icons: ^1.0.8`
- `flutter_lints: ^6.0.0`
- `flutter_secure_storage: ^10.3.1`
- `geolocator: ^14.0.3`
- `flutter_map: ^8.3.1`
- `latlong2: ^0.10.1`
- `go_router: ^17.3.0`
- `sqflite: ^2.4.0`
- `health: ^13.3.1`

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
- Use `.gitignore` for `*.jks`, environment files, and any proprietary configuration files
- Store sensitive data only in `flutter_secure_storage`

### Testing
- Write widget tests for screens
- Write unit tests for controllers, services, and repositories (inject fakes at
  the layer boundary rather than mocking the type under test)
- Test permission flows on both platforms

## Common Patterns

### Navigation
Top-level, auth-guarded routing uses `go_router` in
`lib/core/navigation/app_router.dart`: the router redirects between the splash,
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
- Commit messages: Clear, descriptive (e.g., "Add server settings form with validation")
- Branch strategy: Feature branches for major changes
- Never commit build artifacts, IDE configs, or secrets
