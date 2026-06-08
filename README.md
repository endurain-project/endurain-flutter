<div align="center">
  <img src="assets/logo/logo.png" width="128" height="128">

  # Endurain Mobile

  ![License](https://img.shields.io/github/license/endurain-project/endurain-flutter)
  [![GitHub release](https://img.shields.io/github/v/release/endurain-project/endurain-flutter)](https://github.com/endurain-project/endurain-flutter/releases)
  [![Trademark Policy](https://img.shields.io/badge/trademark-Endurain%E2%84%A2-blue)](TRADEMARK.md)

  **Mobile companion app for Endurain fitness tracking service**  
  Visit Endurain's [Mastodon profile](https://fosstodon.org/@endurain) and [Discord server](https://discord.gg/6VUjUq2uZR).

  <p>
    <i>Cross-platform mobile app for iOS, Android, and macOS</i>
  </p>
</div>

## Table of Contents

- [What is Endurain Mobile?](#what-is-endurain-mobile)
- [Current Features](#current-features)
- [Roadmap](#roadmap)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [SSO/OAuth Callback](#ssooauth-callback)
- [Local Diagnostics](#local-diagnostics)
- [Development Workflow](#development-workflow)
- [Building from Source](#building-from-source)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## What is Endurain Mobile?

Endurain Mobile is the official companion app for [Endurain](https://github.com/endurain-project/endurain), a self-hosted fitness tracking service. Built with Flutter, it provides a native mobile experience for tracking your fitness activities while maintaining full control over your data.

The app is designed with privacy in mind, connecting directly to your self-hosted Endurain server without any third-party services or analytics.

## Current Features

✅ **Authentication**
- Secure login to your Endurain server with PKCE-backed token exchange
- SSO/OAuth support with PKCE (Authentik, Keycloak, Authelia, PocketID, Casdoor, etc.)
- Two-factor authentication (MFA) support
- Auto-redirect for single SSO provider configurations
- Server URL configuration with automatic settings detection
- Access-token refresh and local session restoration

✅ **Map Integration**
- Real-time location display on OpenStreetMap
- Location lock/unlock with visual indicators (filled/outline arrow icons)
- Auto-centering map when location is locked
- Configurable map tile server
- Directional compass heading indicator
- Platform-adaptive UI (Cupertino for iOS/macOS, Material for Android)

✅ **Activity Recording**
- Activity type selection for running, riding, walking, hiking, and other activities
- Start, pause, resume, stop, and discard recording controls directly on the map
- Live activity statistics for duration, distance, and speed
- GPS track capture with elapsed-time tracking across pauses and resumes
- Background location tracking while a recording is active, including Android foreground-service notification support and iOS Always-location guidance
- Location permission and disabled-location error handling, including app settings shortcut
- Stop confirmation flow with discard option
- GPX 1.1 generation from completed tracks
- Direct GPX upload to the Endurain activity import endpoint after a recording completes
- Completed activity retention in private app storage, including local summary metadata, GPX availability, and upload state
- Non-destructive post-upload flow with `Done`, `View history`, retry, and explicit delete actions
- Local activity history and details screens for completed recordings saved on the device

✅ **Settings**
- Server configuration management
- Map tile server customization
- Local activity history entry point and uploaded-GPX retention preference
- Logged-in server and username summary
- Local diagnostics view with privacy-filtered crash context, recording breadcrumbs, copy, and clear actions
- Session management with server-side logout attempt and secure local cleanup
- App version display

✅ **User Experience**
- Multi-language support (English, Portuguese)
- Dark/light theme support
- Secure local session storage
- Shared adaptive widget layer for Material and Cupertino controls
- Local SSO provider icon assets with remote icon fallback

## Roadmap

🚧 **Next Activity Milestones**
- Add a richer local post-recording summary for completed activities before or after upload
- Add manual GPX export/share
- Add server-synced activity history and details once the server exposes stable imported activity metadata
- Improve activity import feedback once the server exposes richer post-upload status and metadata
- Expand activity statistics as server/mobile contracts mature

See the [Activity Tracking MVP Plan](devdocs/activity_tracking_mvp_plan.md) and [Completed Activity Local Retention Plan](devdocs/activity_local_retention_plan.md) for implementation notes and remaining activity work.

## Tech Stack

- **Framework:** Flutter 3.38+ (Dart 3.10+)
- **Platforms:** iOS, Android, macOS
- **State Management:** Stateful widgets plus focused `ChangeNotifier` controllers
- **Map Provider:** OpenStreetMap with `flutter_map` 8.2.x and `latlong2`
- **Location Services:** `geolocator` 14.x, including position streams and movement heading
- **Secure Storage:** `flutter_secure_storage` 10.x
- **HTTP Client:** `http` package for Endurain API communication and multipart uploads
- **SSO/OAuth:** `app_links` for deep-link callbacks, `url_launcher` for system browser OAuth flow, `flutter_svg` for provider icons
- **App Metadata:** `package_info_plus`
- **Local App Files:** `path_provider` for private app-support diagnostics and retained activity GPX storage
- **Security:** `crypto` package for PKCE challenge generation
- **Localization:** Flutter gen-l10n from ARB files with English and Portuguese locales
- **Quality:** `flutter_lints` with strict casts, strict inference, strict raw types, and additional lint rules

## Getting Started

### Prerequisites

- Flutter SDK 3.38 or higher
- Dart SDK 3.10.3 or higher
- Xcode (for iOS/macOS development)
- Android Studio (for Android development)
- A running Endurain server instance

### Installation

1. Clone the repository:
```bash
git clone https://github.com/endurain-project/endurain-flutter.git
cd endurain-flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate localization files:
```bash
flutter gen-l10n
```

4. Run the app:
```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android

# For macOS
flutter run -d macos
```

### Android Device Setup

For Android development, install Android Studio and use its SDK Manager to
install the Android SDK, Platform-Tools, Build-Tools, Command-line Tools, and the
required Android platform packages. Then accept SDK licenses:

```bash
flutter doctor --android-licenses
flutter doctor -v
```

To run on a physical Android device, enable Developer options and USB debugging
on the device, connect it with a data-capable USB cable, and accept the USB
debugging authorization prompt. Verify that Flutter sees the device before
running the app:

```bash
flutter devices
flutter run -d <android-device-id>
```

The Android build scripts use Kotlin DSL (`.kts` files). Flutter's Built-in
Kotlin Gradle flag (`android.builtInKotlin`) is not yet enabled because
`package_info_plus` and `url_launcher_android` still self-apply KGP and are not
compatible with the built-in Kotlin path. The Kotlin plugin is applied
explicitly at version 2.2.20 in `settings.gradle.kts` instead. Once those
plugins ship compatible releases, the explicit declaration can be removed and
the flag enabled. Current Android builds can still show upstream plugin warnings
for these dependencies; if the debug build succeeds, track them with dependency
updates rather than editing files in the local pub cache.

## SSO/OAuth Callback

SSO providers must redirect back to the app with this callback URL:

```text
endurain://auth/sso/callback
```

The callback currently expects a `session_id` query parameter, for example:

```text
endurain://auth/sso/callback?session_id=...
```

Register this callback URL in the Endurain server or identity provider configuration used for mobile SSO.

## Local Diagnostics

The app keeps a local diagnostics report to help investigate field issues when a tethered Flutter or Xcode console is not available. Open **Settings > Diagnostics** after relaunching the app to review recent events, captured Flutter/Dart errors, and the raw privacy-filtered report.

Diagnostics are stored only in the app's private support directory and are never uploaded automatically. The report keeps high-level lifecycle context such as app startup, activity recording start/pause/resume/stop, failure reasons, point-count milestones, and catchable Flutter/Dart errors. It intentionally avoids raw GPS coordinates and sanitizes token-like values, home/container paths, and coordinate-looking strings before saving.

iOS `.ips` crash reports remain separate system-generated native crash reports. The local diagnostics report complements them by preserving app-side context from before the crash.

## Manual QA Checklists

### Android: Active Recording — Location Provider Loss

Native Kotlin unit coverage is not available for the `onProviderDisabled`
path. Use these steps to validate the behavior manually on a physical or
emulated Android device.

**Prerequisites:** A running Endurain server, a connected Android device with
GPS and network location enabled, and developer options active.

1. Open the app and start an activity recording.
2. Verify the foreground-service notification appears and that the recording
   status is active.
3. Background the app (press Home or the recents button).
4. Open the device Settings and disable **all** location providers (both GPS
   and network/Wi-Fi scanning). On most devices this is under
   *Location > App permissions* or by toggling the master location switch.
5. Wait approximately 5–10 seconds for the service to detect the provider
   change.
6. Return to the app.

**Expected results:**
- The recording shows a non-recoverable failed state (not an active or paused
  state).
- No "resume recording" option is offered.
- After fully restarting the app (force-stop and reopen), no phantom active
  session is restored from the saved session file.
- The local activity history shows the completed (or failed) entry with the
  points collected before providers were disabled.

**Recovery path:** Re-enable location providers, then start a new recording
as normal.

## Development Workflow

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Collect coverage and check a minimum line coverage threshold:

```bash
flutter test --coverage
dart run tool/check_coverage.dart \
  --min-line-coverage 80 \
  --min-file-line-coverage 60 \
  --exclude "lib/l10n/app_localizations*.dart" \
  --exclude "lib/core/theme/app_theme_tokens.dart" \
  --exclude "lib/core/navigation/app_routes.dart" \
  --exclude "lib/shared/widgets/app_bottom_nav.dart" \
  --exclude "lib/core/services/location_platform_adapter.dart" \
  --exclude "lib/core/services/multipart_upload_adapter.dart" \
  --exclude "lib/core/services/package_info_service.dart" \
  --exclude "lib/core/services/url_launcher_service.dart"
```

Regenerate localization classes after changing ARB files:

```bash
flutter gen-l10n
```

Localization source files live in `lib/l10n/app_en.arb` and `lib/l10n/app_pt.arb`. Every ARB entry must include resource attributes because `l10n.yaml` enables `required-resource-attributes`.

## Building from Source

### iOS

```bash
flutter build ios --release
```

### Android

Debug builds do not require release signing credentials:

```bash
flutter build apk --debug
```

Release builds require Android signing configuration. Copy
`android/key.properties.example` to ignored `android/key.properties` and fill it
locally, or provide the documented `ANDROID_KEYSTORE_*` environment variables in
CI.

```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### macOS

```bash
flutter build macos --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root app widget
├── core/
│   ├── constants/            # App-wide constants (API, UI, map)
│   ├── models/               # Shared app models and exception types
│   ├── navigation/           # Route names
│   ├── services/             # API, auth, storage, links, location, package info
│   ├── theme/                # Theme configuration and tokens
│   └── utils/                # Validators, dialogs, error localization, platform helpers
├── features/
│   ├── activity/             # Recording controllers, models, services, and widgets
│   ├── auth/                 # Login, MFA, SSO, and session controllers
│   ├── map/                  # Map screen, map settings, and location state
│   └── settings/             # Settings and server configuration screens
├── shared/
│   ├── adaptive/             # Material/Cupertino adaptive components
│   └── widgets/              # Shared app widgets
└── l10n/                     # ARB files and generated localizations
test/
├── core/                     # Unit tests for services, models, and utilities
├── features/                 # Feature unit and widget tests
├── shared/                   # Adaptive widget tests
├── helpers/                  # Test fakes and widget harnesses
└── tool/                     # Tooling tests, including coverage checker tests
tool/
└── check_coverage.dart       # LCOV coverage threshold utility
```

## Local Activity Storage Design

Activities are recorded and saved on-device for upload to the server.

### Current layout (JSON manifest)

Completed recordings are stored under the app's private support directory:

```
<support-dir>/
├── index.json                 # JSON array of LocalActivityRecord objects (schema v1)
└── gpx/
    └── <activity-id>.gpx      # Raw GPX 1.1 file for each recording
```

`index.json` is read and written atomically via a rename-on-write pattern.
Each entry in the array contains: `id`, `activityType`, timing, distance,
`pointCount`, `gpxFileName`, `uploadStatus`, and upload timestamps.

### Target layout (SQLite — planned)

A future migration will move the metadata store to SQLite for better
concurrent safety, range queries, and row-level updates without rewriting
the entire file:

| Table                  | Purpose                                                  |
|------------------------|----------------------------------------------------------|
| `schema_version`       | Single-row version counter used to gate migrations.      |
| `local_activity`       | One row per activity, all metadata columns.              |

GPX files will remain on disk under `gpx/` — only the metadata moves.

### Migration plan (schema v1 → SQLite)

1. On first SQLite open, detect an existing `index.json` manifest.
2. Import all valid records into the `local_activity` table.
3. Leave `index.json` on disk until the import succeeds (rollback safety).
4. Remove `index.json` after a successful import.
5. Malformed or partially-corrupt manifest entries are skipped with a
   diagnostics breadcrumb; valid entries are not affected.

### Rollback/failure behavior

If the SQLite open or migration fails, the app falls back to reading
`index.json` as before. No data loss occurs because `index.json` is kept
in place until migration is confirmed complete.

### SQLite package decision

**Chosen: `sqflite` + `sqflite_common_ffi`**

| Package               | License    | Reason                                         |
|-----------------------|------------|------------------------------------------------|
| `sqflite`             | Apache 2.0 | De facto Flutter SQLite; Android/iOS native    |
| `sqflite_common_ffi`  | MIT        | macOS/desktop support and in-process testing   |

Both packages are open-source and contain no proprietary SDKs, making them
suitable for F-Droid distribution. `sqflite_common_ffi` enables the same API
on macOS and in unit tests without platform-channel mocks.

`drift` (an ORM built on SQLite) was considered but rejected — the direct SQL
API of `sqflite` is sufficient for the planned schema and avoids an additional
code-generation dependency.

## Contributing

Contributions are welcomed! This mobile app is part of the main Endurain project. Please:

1. Check the [Contributing Guidelines](CONTRIBUTING.md)
2. Open an issue to discuss changes before submitting a PR
3. Follow the existing code style and architecture patterns
4. Ensure all dependencies remain FOSS-compatible
5. Test on multiple platforms when possible

### Development Guidelines

- **Never hardcode strings** - use `AppLocalizations` (l10n)
- **Use constants** - avoid magic numbers, use files in `core/constants/`
- **Platform-adaptive UI** - use `PlatformUtils` for platform checks
- **Follow conventions** - see `.github/copilot-instructions.md`

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Trademark Notice

Endurain® is a trademark of João Vitória Silva.  

You are welcome to self-host Endurain and use the name and logo, including for personal, educational, research, or community (non-commercial) use.  
Commercial use of the Endurain name or logos (such as offering paid hosting, products, or services) is **not permitted without prior written permission**.

See [`TRADEMARK.md`](TRADEMARK.md) for full details.

---

<div align="center">
  <sub>Built with ❤️ from Portugal | Part of the <a href="https://github.com/endurain-project">Endurain</a> ecosystem</sub>
</div>