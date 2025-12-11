# Copilot Instructions for Endurain Mobile

## Tech Stack
- **Flutter**: 3.38+ (stable channel)
- **Dart**: 3.10+
- **Platforms**: Android, iOS, macOS
- **State Management**: setState (basic) - may evolve to Provider/Riverpod
- **Map Provider**: OpenStreetMap (flutter_map + latlong2) - **F-Droid compatible**
- **Secure Storage**: flutter_secure_storage
- **Location**: geolocator
- **F-Droid Compatible**: All dependencies are open-source (FOSS)

## Code Conventions

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
- Supported languages: English (en), Portuguese (pt)
- **Translations organized by feature** in `lib/l10n/app_en.arb` and `app_pt.arb`
  - Sections: Common/Shared, Auth, Map, Settings (see `lib/l10n/README.md`)
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

## Package Versions (Reference)
Update with actual versions used:
- `cupertino_icons: ^1.0.8`
- `flutter_lints: ^6.0.0`
- `flutter_secure_storage: ^9.0.0` (to be added)
- `geolocator: ^13.0.0` (to be added)
- `flutter_map: ^7.0.0` (to be added)
- `latlong2: ^0.9.0` (to be added)

**Note:** Only open-source packages are used to maintain F-Droid compatibility. Do NOT add Google Maps, Firebase, or other proprietary dependencies.

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

### F-Droid Compatibility
- **Only use open-source dependencies** - check licenses before adding packages
- Avoid Google Play Services, Firebase, and other proprietary SDKs
- Use OpenStreetMap (`flutter_map`) instead of Google Maps
- Ensure all dependencies have compatible licenses (MIT, BSD, Apache 2.0, etc.)

### Testing
- Write widget tests for screens
- Write unit tests for services
- Test permission flows on both platforms

## Common Patterns

### Navigation
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
