<div align="center">
  <img src="assets/logo/brand_logo_light_theme.png" width="128" height="128">

  # Endurain mobile app

  ![License](https://img.shields.io/github/license/endurain-project/endurain-flutter)
  [![GitHub release](https://img.shields.io/github/v/release/endurain-project/endurain-flutter)](https://github.com/endurain-project/endurain-flutter/releases)
  [![Trademark Policy](https://img.shields.io/badge/trademark-Endurain%E2%84%A2-blue)](TRADEMARK.md)

  **Mobile companion app for Endurain fitness tracking service**  
  Visit Endurain's [Mastodon profile](https://fosstodon.org/@endurain) and [Discord server](https://discord.gg/6VUjUq2uZR).

  <p>
    <i>Cross-platform mobile app for iOS and Android</i>
  </p>
</div>

## Table of Contents

- [What is Endurain mobile app?](#what-is-endurain-mobile)
- [Current Features](#current-features)
- [Roadmap](#roadmap)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Health Platform Permissions](#health-platform-permissions)
- [SSO/OAuth Callback](#ssooauth-callback)
- [Local Diagnostics](#local-diagnostics)
- [Development Workflow](#development-workflow)
- [Building from Source](#building-from-source)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## What is Endurain mobile app?

Endurain mobile app is the official companion app for [Endurain](https://github.com/endurain-project/endurain), a self-hosted fitness tracking service. Built with Flutter, it provides a native mobile experience for tracking your fitness activities while maintaining full control over your data.

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
- Platform-adaptive UI (Cupertino for iOS, Material for Android)

✅ **Activity Recording**
- Activity type selection for running, riding, walking, hiking, and other activities
- Start, pause, resume, stop, and discard recording controls directly on the map
- Live activity statistics for duration, distance, speed, and live heart rate when a Bluetooth sensor is connected
- GPS track capture with elapsed-time tracking across pauses and resumes
- Background location tracking while a recording is active, including Android foreground-service notification support and iOS Always-location guidance
- Location permission and disabled-location error handling, including app settings shortcut
- Stop confirmation flow with discard option
- GPX 1.1 generation from completed tracks
- Direct GPX upload to the Endurain activity import endpoint after a recording completes
- Completed activity retention in private app storage (SQLite metadata store + GPX files), including local summary metadata, GPX availability, and upload state
- Non-destructive post-upload flow with `Done`, `View history`, retry, and explicit delete actions
- Richer local post-recording summary shown on the map when a recording completes, before or after upload: activity type, start time, duration, distance, average pace/speed, max speed, elevation gain, and GPS point count. Max speed and elevation gain are persisted and also shown on the saved activity details screen
- Durable upload recovery: a finished activity is always saved locally first. Transient network, timeout, and server failures remain eligible for automatic recovery by an app-lifetime upload queue on app resume or restored connectivity. Validation, authentication, configuration, and missing-file failures stay available for explicit manual retry instead of looping on every resume. Drain requests received during an active run trigger a follow-up scan so newly imported activities are not stranded
- Forward-compatible upload de-duplication: each upload carries the local activity id as an `Idempotency-Key` request header. This is fully optional on the server — Endurain servers that do not recognize the header simply ignore it and uploads work unchanged, while a server that adopts it can de-duplicate automatically retried uploads with no app changes
- Local activity history and details screens for completed recordings saved on the device, with incremental pagination
- Activity route preview map on the details screen, drawn from the retained GPX file on OpenStreetMap tiles (shown while the GPX is still stored on the device)
- Manual GPX export/share from the activity details screen via the OS share sheet

✅ **Settings**
- Server configuration management
- Map tile server customization
- Persisted language selection with a system-default option
- Local activity history entry point and uploaded-GPX retention preference
- Device access overview for location and health-data permissions
- Bluetooth heart-rate sensor pairing and connection status (Sensors screen)
- Health sync settings and optional automatic import on app resume
- Logged-in server and username summary
- Local diagnostics view with privacy-filtered crash context, recording breadcrumbs, copy, and clear actions
- Session management with server-side logout attempt and secure local cleanup
- App version display

✅ **Health Data Sync**
- Import route-bearing workouts from Apple HealthKit on iOS and Health Connect on Android
- Review and request access to workouts, workout routes, heart rate, and the distance, calories, and steps that Health Connect uses to summarize workouts
- Browse the last 30 days by default, or choose three months, six months, one year, all history, or a custom date range; older history is read in 30-day pages so wide searches do not become a single expensive platform query
- Select one or more eligible workouts, use `Select all` for the currently loaded page set, and commit them through one explicit import action; unavailable workouts remain informational rows without selection controls
- Review imported workouts for the active connection, including their local upload status, and open records that are still available on the device
- Restore an imported workout only when its local record is missing. Discovery is read-only and never clears provenance implicitly, so background sync cannot recreate an intentionally deleted activity without that explicit action
- Convert imported routes to GPX and feed them into the same durable local upload queue used by GPS recording
- Prevent duplicate imports locally and use stable upload idempotency keys
- Optionally import new workouts automatically when the app resumes; automatic discovery remains bounded to the default 30-day window
- Health-derived activity files and databases live in dedicated no-backup storage on Android and iOS; imported data can be deleted from local activity history or reset from Health access settings
- Import provenance is scoped to the active connection profile, and health UI controllers are route-owned so imported rows and selections cannot survive a logout/login transition. A backend account UUID is still required before separate login profiles can safely share imported history across sign-out and
  sign-in cycles

✅ **External Sensors (Bluetooth heart rate)**
- Pair a Bluetooth Low Energy heart-rate monitor from **Settings > Sensors** and see the live BPM
- Live heart rate on the map: a pill at the top of the map when idle, and a live value in the recording statistics while an activity records
- Heart rate is stamped onto recorded GPX track points, so the uploaded activity includes it
- A remembered sensor reconnects automatically when the app opens, with a "searching" indicator and bounded retry, so the strap does not need re-pairing each session
- Heart-rate capture continues in the background during a recording: on Android the foreground-service recorder owns the connection, while on iOS the in-app connection is kept via the Bluetooth background mode
- Uses `universal_ble` (BSD-3-Clause, no Google Play Services, F-Droid compatible); the app requests the Bluetooth runtime permissions itself

✅ **User Experience**
- Multi-language support for 30 locales, including English and European Portuguese
- Dark/light theme support
- Secure local session storage
- Shared adaptive widget layer for Material and Cupertino controls
- Platform-native health controls: Material checkboxes for Android batch selection, whole-row selection with trailing checkmarks on iOS, switches only for immediate settings, accurate sport glyphs on both platforms, and tested dark-mode/200% text layouts
- Local SSO provider icon assets with remote icon fallback

## Roadmap

🚧 **Next Activity Milestones**
- Add server-synced activity history and details once the server exposes stable imported activity metadata
- Improve activity import feedback once the server exposes richer post-upload status and metadata
- Expand activity statistics as server/mobile contracts mature

See [Local Activity Storage Design](#local-activity-storage-design) below for the current on-device storage design behind activity recording and retention.

## Tech Stack

- **Framework:** Flutter 3.44+ (Dart 3.12+)
- **Platforms:** iOS, Android
- **State Management:** Focused `ChangeNotifier` view-model controllers wired in a composition root (`AppServices`) and obtained via `AppScope`
- **Navigation:** `go_router` for top-level, auth-guarded routing that redirects off the session state and is ready for deep links
- **Map Provider:** OpenStreetMap with `flutter_map` and `latlong2`
- **Location Services:** `geolocator`, including position streams and movement heading
- **Connectivity:** `connectivity_plus` to retry pending activity uploads when the network returns
- **File Sharing:** `share_plus` for the OS share sheet used by GPX file export
- **Secure Storage:** `flutter_secure_storage`
- **HTTP Client:** `http` for Endurain API communication and multipart uploads
- **SSO/OAuth:** `app_links` for deep-link callbacks, `url_launcher` for the system browser OAuth flow, and `flutter_svg` for provider icons
- **Health Data:** `health` for Apple HealthKit and Android Health Connect workout import
- **External Sensors:** `universal_ble` for Bluetooth Low Energy heart-rate monitors (BSD-3-Clause, no Google Play Services)
- **App Metadata:** `package_info_plus`
- **Local App Files:** `path_provider` for private app-support diagnostics and retained activity GPX storage
- **Preferences:** `shared_preferences` for non-secret display and language settings
- **Security:** `crypto` for PKCE challenge generation
- **Localization:** Flutter gen-l10n from ARB files with 30 supported locales
- **SQLite:** `sqflite` for on-device metadata storage and `sqflite_common_ffi` for test-only in-process coverage
- **Quality:** `flutter_lints` with strict casts, strict inference, strict raw types, and additional lint rules

## Getting Started

### Prerequisites

- Flutter SDK 3.44.1 or higher
- Dart SDK 3.12.0 or higher
- Xcode (for iOS development)
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
```

### Android Device Setup

For Android development, install Android Studio and use its SDK Manager to
install the Android SDK, Platform-Tools, Build-Tools, Command-line Tools, and the
required Android platform packages. Then accept SDK licenses:

```bash
flutter doctor --android-licenses
flutter doctor -v
```

To run on a physical Android device, enable Developer options and USB debugging on the device, connect it with a data-capable USB cable, and accept the USB debugging authorization prompt. Verify that Flutter sees the device before running the app:

```bash
flutter devices
flutter run -d <android-device-id>
```

The Android build scripts use Kotlin DSL (`.kts` files). Flutter's Built-in Kotlin Gradle flag (`android.builtInKotlin`) is not yet enabled because `package_info_plus` and `url_launcher_android` still self-apply KGP and are not compatible with the built-in Kotlin path. The Kotlin plugin is applied explicitly at version 2.2.20 in `settings.gradle.kts` instead. Once those plugins ship compatible releases, the explicit declaration can be removed and the flag enabled. Current Android builds can still show upstream plugin warnings for these dependencies; if the debug build succeeds, track them with dependency updates rather than editing files in the local pub cache.

### Android Health Sync Availability

Health sync is optional. Android 14 and later include Health Connect as a system component. On earlier Android versions, the user must install the separate Health Connect provider before importing workouts. On devices where the provider is unavailable, the app keeps GPS recording and manual GPX upload available and shows health sync as unavailable.

### Health Platform Permissions

Health sync is read-only. Endurain requests only the health data needed to find
workouts and convert route-bearing workouts to GPX. Users grant access through
the platform authorization screen and can revoke it later in Apple Health or
Health Connect settings.

On iOS, the Runner target requires the HealthKit capability
(`com.apple.developer.healthkit`) and `NSHealthShareUsageDescription`. At
runtime, Endurain requests read access to:

- Workouts, to discover activity sessions and their start/end times.
- Workout routes, to build the GPX track required for import.
- Heart rate, to attach available samples to GPX track points.

Endurain does not request HealthKit write access. HealthKit intentionally does
not reveal individual read-grant status, so users manage those choices in the
Health app or iOS Settings.

On Android, the manifest declares these Health Connect permissions:

- `READ_EXERCISE`, to discover exercise sessions.
- `READ_DISTANCE`, `READ_TOTAL_CALORIES_BURNED`, and `READ_STEPS`, because the
  pinned `health` package reads those records while constructing every workout
  summary. Omitting any of them can make its Android workout query return an
  empty list.
- `READ_HEART_RATE`, to attach available samples to GPX track points.
- `READ_EXERCISE_ROUTES`, to retrieve the GPS route. Health Connect may require
  separate user consent for routes written by another app.
- `READ_HEALTH_DATA_HISTORY`, to read beyond Health Connect's standard 30-day
  window. Endurain requests this only when the selected range reaches older
  data and falls back to the readable recent window if the user declines.

After an app update adds a new Health Connect permission, existing users must
open Health sync and authorize access again; Android does not add the new grant
automatically.

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

For production deployments that control a public domain, verified HTTPS callbacks are the preferred mobile best practice. Android App Links and iOS Universal Links let the operating system verify that the domain is allowed to open the Endurain app, reducing custom-scheme hijacking and misrouting risk. PKCE still protects the current custom-scheme flow, but verified links provide a stronger OS-level ownership check.

Using verified callbacks requires both app and server/domain configuration:

- Configure the mobile app to accept the HTTPS callback path with Android `android:autoVerify="true"` App Links and iOS Associated Domains.
- Serve Android Digital Asset Links from `https://<your-domain>/.well-known/assetlinks.json`.
- Serve the Apple App Site Association file from `https://<your-domain>/.well-known/apple-app-site-association`.
- Add the HTTPS callback URL to the Endurain server and identity-provider allowed redirect/callback URL configuration.

Keeping both callback styles during migration is recommended: continue to support `endurain://auth/sso/callback` for existing deployments while adding a verified HTTPS callback for domains that can publish the required `.well-known` files.

## Local Diagnostics

The app keeps a local diagnostics report to help investigate field issues when a tethered Flutter or Xcode console is not available. Open **Settings > Diagnostics** after relaunching the app to review recent events, captured Flutter/Dart errors, and the raw privacy-filtered report.

Diagnostics are stored only in the app's private support directory and are never uploaded automatically. The report keeps high-level lifecycle context such as app startup, activity recording start/pause/resume/stop, failure reasons, point-count milestones, and catchable Flutter/Dart errors. It intentionally avoids raw GPS coordinates and sanitizes token-like values, home/container paths, and coordinate-looking strings before saving.

iOS `.ips` crash reports remain separate system-generated native crash reports. The local diagnostics report complements them by preserving app-side context from before the crash.

## Manual QA Checklists

### Android: Active Recording — Location Provider Loss

Native Kotlin unit coverage is not available for the `onProviderDisabled` path. Use these steps to validate the behavior manually on a physical or emulated Android device.

**Prerequisites:** A running Endurain server, a connected Android device with GPS and network location enabled, and developer options active.

1. Open the app and start an activity recording.
2. Verify the foreground-service notification appears and that the recording status is active.
3. Background the app (press Home or the recents button).
4. Open the device Settings and disable **all** location providers (both GPS and network/Wi-Fi scanning). On most devices this is under *Location > App permissions* or by toggling the master location switch.
5. Wait approximately 5–10 seconds for the service to detect the provider change.
6. Return to the app.

**Expected results:**
- The recording shows a non-recoverable failed state (not an active or paused state).
- No "resume recording" option is offered.
- After fully restarting the app (force-stop and reopen), no phantom active session is restored from the saved session file.
- The local activity history shows the completed (or failed) entry with the points collected before providers were disabled.

**Recovery path:** Re-enable location providers, then start a new recording as normal.

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
  --exclude "lib/core/services/platform/*.dart" \
  --exclude "lib/features/health/services/health_package_platform_adapter.dart" \
  --exclude "lib/features/sensors/services/universal_ble_heart_rate_sensor_adapter.dart"
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
`android/key.properties.example` to ignored `android/key.properties` and fill it locally, or provide the documented `ANDROID_KEYSTORE_*` environment variables in CI. A release build now fails rather than falling back to the debug key when any signing input is missing.

Forgejo release builds require these repository secrets:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded upload keystore.
- `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`: upload-key credentials.
- `ANDROID_UPLOAD_CERT_SHA256`: expected SHA-256 certificate fingerprint, with or without colon separators.

For a published release, CI derives `versionName` from its `vX.Y.Z` tag and uses the Forgejo release ID as the monotonic Android `versionCode`. Manual workflow runs require an explicit semantic `version_name` and positive, monotonically increasing `version_code`.

```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root app widget
├── core/
│   ├── config/               # App configuration and environment helpers
│   ├── constants/            # App-wide constants (API, UI, map)
│   ├── models/               # Shared app models and exception types
│   ├── navigation/           # Route names and the go_router auth-guard config
│   ├── services/             # API, auth, storage, links, location, package info
│   ├── theme/                # Theme configuration and tokens
│   └── utils/                # Validators, dialogs, error localization, platform helpers
├── features/
│   ├── activity/             # Recording controllers, models, repositories, services, screens, and widgets
│   ├── auth/                 # Login, MFA, SSO, and session controllers
│   ├── health/               # HealthKit/Health Connect import, sync, and access screens
│   ├── map/                  # Map screen, map settings, and location state
│   ├── sensors/              # Bluetooth heart-rate sensor pairing and live BPM
│   └── settings/             # Settings and server configuration screens
├── shared/
│   ├── adaptive/             # Material/Cupertino adaptive components
│   ├── state/                # Shared state helpers and controllers
│   └── widgets/              # Shared app widgets
└── l10n/                     # ARB files and generated localizations
test/
├── architecture/             # Architecture and integration-style tests
├── core/                     # Unit tests for services, models, and utilities
├── features/                 # Feature unit and widget tests
├── helpers/                  # Test fakes and widget harnesses
├── l10n/                     # Localization and resource tests
├── shared/                   # Adaptive widget tests
└── tool/                     # Tooling tests, including coverage checker tests
tool/
└── check_coverage.dart       # LCOV coverage threshold utility
```

## Local Activity Storage Design

Activities are recorded and saved on-device for upload to the server. Metadata is stored in SQLite (via `SqfliteActivityStore`), while GPX tracks remain as files on disk.

### Current layout (SQLite metadata + GPX files)

Completed recordings are stored under the app's private support directory:

```
<app-support>/
└── activity_records/
    └── gpx/
        └── <activity-id>.gpx      # Raw GPX 1.1 file for each recording
```

Activity metadata lives in a SQLite database (`activity.db`, schema v8) under the platform databases directory. The database holds two tables:

| Table                  | Purpose                                                  |
|------------------------|----------------------------------------------------------|
| `schema_version`       | Single-row version counter used to gate migrations.      |
| `local_activity`       | One row per activity, all metadata columns.              |

Each `local_activity` row contains: `id`, `activity_type`, `started_at`, `ended_at`, `elapsed_duration_seconds`, `distance_meters`, `average_speed_meters_per_second`, `max_speed_meters_per_second`, `elevation_gain_meters`, `point_count`, `gpx_file_name`, `upload_status`, `idempotency_key`, `connection_origin`, `connection_profile_id`, `auto_retry_eligible`, `gpx_cleanup_pending`, `created_at`, `updated_at`, `uploaded_at`, `last_upload_attempt_at`, and `last_upload_error_code`. GPX files live on disk under `gpx/` — only the metadata is stored in the database. Health-imported activities are additionally tracked for provenance and de-duplication in a separate `health_import.db` (schema v3).

### Schema migrations

Schema changes are applied through an ordered, append-only migration map keyed by target version. Fresh installs (`onCreate`) and upgrades (`onUpgrade`) run the same migration steps, so the schema is produced by exactly one code path. To evolve the schema, append a new migration and bump the schema version — shipped migrations are never edited.

### SQLite package decision

**Chosen: `sqflite` (with `sqflite_common_ffi` for tests only)**

| Package               | License    | Reason                                         |
|-----------------------|------------|------------------------------------------------|
| `sqflite`             | Apache 2.0 | De facto Flutter SQLite; Android/iOS native    |
| `sqflite_common_ffi`  | MIT        | In-process SQLite for unit tests (dev only)    |

`sqflite` provides the shipped Android/iOS implementation, while `sqflite_common_ffi` is a `dev_dependency` that runs the same API in-process during unit tests without platform-channel mocks.

`drift` (an ORM built on SQLite) was considered but rejected — the direct SQL API of `sqflite` is sufficient for the current schema and avoids an additional code-generation dependency.

## Contributing

Contributions are welcomed! This mobile app is part of the main Endurain project. Please:

1. Check the [Contributing Guidelines](CONTRIBUTING.md)
2. Open an issue to discuss changes before submitting a PR
3. Follow the existing code style and architecture patterns
4. Test on multiple platforms when possible

### Development Guidelines

- **Never hardcode strings** - use `AppLocalizations` (l10n)
- **Use constants** - avoid magic numbers, use files in `core/constants/`
- **Platform-adaptive UI** - use `PlatformUtils` for platform checks
- **Open-source first** - prefer well-maintained open-source dependencies when they meet the need; proprietary or store-specific SDKs are acceptable when their product or platform benefit is clear
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