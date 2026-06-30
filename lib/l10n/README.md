# Localization (l10n) Organization

This directory contains the app's translations organized by feature.

## Files

- `app_en.arb` - English translations (template)
- `app_pt.arb` - Portuguese translations
- `l10n.yaml` - Flutter localization configuration

## Structure

Translations are organized into **logical sections** with comment headers to make it easy to find and maintain strings:

### 1. **COMMON / SHARED**
Used by: `core/utils/dialog_utils.dart`, `core/utils/validators.dart`
- Generic dialogs (error, ok, cancel)
- Validation messages (requiredField, invalidUrl)
- Common actions (save, back)

### 2. **AUTH**
Used by: `features/auth/screens/login_screen.dart`
- Login screen (loginTitle, login, username, password)
- MFA flow (mfaTitle, mfaCode, verify)
- Logout (logout, logoutConfirmTitle, logoutConfirmMessage)

### 3. **ERRORS**
Used by: `core/models/app_exception.dart`, `core/utils/error_localizations.dart`
- Stable app error messages mapped from `AppErrorCode`
- User-facing translations for service-layer failures
- Optional `{details}` variants for server-provided or technical context

### 4. **ACTIVITY**
Used by: `features/activity/`
- Activity type labels
- Recording controls, stats, stop/discard dialogs, upload states, and location errors

### 5. **MAP**
Used by: `features/map/screens/map_screen.dart`
- Map tab label
- Location control tooltips

### 6. **SETTINGS**
Used by: `features/settings/screens/settings_screen.dart`, `features/settings/screens/server_settings_screen.dart`
- Settings navigation (settingsTab, settingsScreen)
- Server configuration (serverUrl, tileServerUrl, loggedIn)
- Save messages (savedSuccessfully)

## Adding New Translations

When adding a new translation:

1. **Find the right section** in both `app_en.arb` and `app_pt.arb`
2. **Add the key** in alphabetical order within that section
3. **Include usage info** in the description: `"description": "Button label - Used in: your_screen.dart"`
4. **Run** `flutter gen-l10n` to regenerate localization classes
5. **Update this README** if adding a new section

For user-facing errors, add a value to `AppErrorCode`, map it in
`error_localizations.dart`, then add the matching ARB keys. Services should
throw `AppException` with a stable code instead of hardcoded English strings.

## Usage Example

```dart
import 'package:endurain/l10n/app_localizations.dart';

// In your widget:
final l10n = AppLocalizations.of(context)!;

Text(l10n.login);  // "Login" (en) or "Entrar" (pt)
```

## Quick Reference

| Feature | Keys |
|---------|------|
| Common | error, ok, cancel, save, back, requiredField, invalidUrl |
| Auth | loginTitle, login, logout, username, password, mfaTitle, mfaCode, verify |
| Errors | errorServerUrlNotConfigured, errorNotAuthenticated, errorSessionExpired, errorLoginFailed, errorTokenExchangeFailed |
| Activity | activityStart, activityPause, activityStop, activityStatDistance, activityRetryUpload, activityTypeRun, activityTypeRide, activityTypeWalk, activityTypeHike, activityTypeOther |
| Map | mapTab, myLocation |
| Settings | settingsTab, settingsScreen, serverSettings, serverUrl, tileServerUrl, notConfigured, notLoggedIn, savedSuccessfully |

## Why Not Split Files?

Flutter's l10n system requires a single ARB file per locale (cannot merge multiple ARB files). We use **comment sections** instead to organize translations logically while maintaining compatibility with Flutter's tooling.

## Translation Keys Convention

- **camelCase** for all keys (e.g., `loginTitle`, not `login_title`)
- **Descriptive names** that indicate purpose (e.g., `mfaCodeRequired` not `error1`)
- **Feature prefixes** when needed (e.g., `mapTab`, `settingsTab`)
- **Context in description** showing which files use the translation

## Generation Guardrails

The root `l10n.yaml` enables `required-resource-attributes` so every user-facing
string needs metadata, and writes missing translations to
`build/untranslated_messages.json`. Treat that file as a CI signal: it should be
empty or absent after `flutter gen-l10n`.
