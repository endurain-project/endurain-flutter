<div align="center">
  <img src="assets/logo/brand_logo_light_theme.png" width="128" height="128">

  # Endurain mobile app

  [![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](LICENSE)
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
- Optional spoken progress announcements at distance or elapsed-time milestones, configured per activity type in **Settings > Audio Announcements**. Speech is produced entirely on-device (Android `TextToSpeech`, iOS `AVSpeechSynthesizer`) with no network access, announces distance, elapsed time, and lap plus overall pace or speed, and can duck other audio while speaking. Announcements keep playing while the recording is backgrounded: on Android the foreground-service recorder speaks them, while on iOS they use the audio background mode and the audio session is activated only around an utterance

✅ **Settings**
- Server configuration management
- Map tile server customization
- Persisted language selection with a system-default option
- Local activity history entry point and uploaded-GPX retention preference
- Audio announcement preferences: master switch, audio ducking, and a per-activity-type distance or time interval
- Per-activity audio announcement preview that speaks one sample milestone, so a missing or muted device speech engine is detectable before starting an activity
- Device access overview for location and health-data permissions
- Bluetooth heart-rate sensor pairing and connection status (Sensors screen)
- Health sync settings and optional automatic import on app resume
- Logged-in server and username summary
- Local diagnostics view with privacy-filtered crash context, recording breadcrumbs, copy, and clear actions
- Optional, opt-in remote crash reporting to Endurain's managed diagnostics service (`diagnostics.endurain.com`), independent of local diagnostics
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

✅ **External Sensors (Bluetooth)**
- Pair Bluetooth Low Energy heart-rate monitors, cycling power meters, and cycling or running cadence sensors from **Settings > Sensors**
- View live heart rate, power, and cadence measurements on the map and in recording statistics
- Sensor measurements are stamped onto recorded GPX track points when supported by the measurement type
- A remembered sensor reconnects automatically when the app opens, with a "searching" indicator and bounded retry, so it does not need re-pairing each session
- Sensor capture continues in the background during a recording: on Android the foreground-service recorder owns the connection, while on iOS the in-app connection is kept via the Bluetooth background mode
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

- **Framework:** Flutter 3.50+ (Dart 3.14+)
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
- **External Sensors:** `universal_ble` for Bluetooth Low Energy heart-rate monitors, cycling power meters, and cadence sensors (BSD-3-Clause, no Google Play Services)
- **App Metadata:** `package_info_plus` for the app version, and `device_info_plus` for the OS version and device model in the local diagnostics report
- **Local App Files:** `path_provider` for private app-support diagnostics and retained activity GPX storage
- **Preferences:** `shared_preferences` for non-secret display and language settings
- **Security:** `crypto` for PKCE challenge generation
- **Crash Reporting:** opt-in `sentry` (pure-Dart, Sentry protocol) for remote error reports to Endurain's managed diagnostics endpoint, behind an injectable `CrashReporter` adapter
- **Localization:** Flutter gen-l10n from ARB files with 30 supported locales
- **SQLite:** `sqflite` for on-device metadata storage and `sqflite_common_ffi` for test-only in-process coverage
- **Quality:** `flutter_lints` with strict casts, strict inference, strict raw types, and additional lint rules

## Getting Started

### Prerequisites

- Flutter SDK 3.50.0 or higher
- Dart SDK 3.14.0 or higher
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

The Android build scripts use Kotlin DSL (`.kts` files). Flutter's Built-in Kotlin Gradle flag (`android.builtInKotlin`) is not yet enabled because `health` still self-applies KGP and is not compatible with the built-in Kotlin path. The Kotlin plugin is applied explicitly at version 2.4.0 in `settings.gradle.kts` instead. Once that plugin ships a compatible release, the explicit declaration can be removed and the flag enabled. Current Android builds can still show upstream plugin warnings for this dependency; if the debug build succeeds, track them with dependency updates rather than editing files in the local pub cache.

### Android Health Sync Availability

Health sync is optional. Android 14 and later include Health Connect as a system component. On earlier Android versions, the user must install the separate Health Connect provider before importing workouts. On devices where the provider is unavailable, the app keeps GPS recording and manual GPX upload available and shows health sync as unavailable.

### Health Platform Permissions

Health sync is read-only. Endurain requests only the health data needed to find
workouts and convert route-bearing workouts to GPX. Users grant access through
the platform authorization screen and can revoke it later in Apple Health or
Health Connect settings.

On iOS, the Runner target requires the HealthKit capability
(`com.apple.developer.healthkit`), `NSHealthShareUsageDescription`, and
`NSHealthUpdateUsageDescription` (required by the HealthKit integration even
though Endurain imports data only). At runtime, Endurain requests read access
to:

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

The app signs in with SSO using PKCE, and the server sends the browser back to the app at this callback URL (Android and iOS):

```text
com.endurain.endurain:/auth/sso/callback
```

This is the reverse-DNS custom scheme form that RFC 8252 recommends, and it is the default `ALLOWED_REDIRECT_URIS` of an Endurain v0.21+ server. If your server overrides `ALLOWED_REDIRECT_URIS`, the list must include this exact URL. The app reads the server's allowed list before opening the browser and shows an error instead of starting a sign-in the server would reject.

A successful sign-in returns a `session_id` query parameter, which the app exchanges for tokens with its PKCE verifier:

```text
com.endurain.endurain:/auth/sso/callback?session_id=...
```

A failed sign-in returns an `error` parameter instead (for example `sso_email_unverified`). The app shows a specific message only for the failure codes the server documents and a generic one for anything else.

The old `endurain://auth/sso/callback` address is no longer registered, so links to it do not open the app.

Incoming links are handled by `app_links`, so Flutter's built-in deep linking is turned off (`flutter_deeplinking_enabled` in `AndroidManifest.xml`, `FlutterDeepLinkingEnabled` in `Info.plist`). Leave it off: when it is on, the router also receives the callback, sends it to home, and closes the login screen before the sign-in finishes.

For production deployments that control a public domain, verified HTTPS callbacks are a stronger option. Android App Links and iOS Universal Links let the operating system verify that the domain is allowed to open the Endurain app, which reduces the risk of another app claiming the custom scheme. PKCE already protects the custom-scheme flow, but verified links add an OS-level ownership check. The app does not support an HTTPS callback yet. Adding one needs both app and server/domain configuration:

- Configure the mobile app to accept the HTTPS callback path with Android `android:autoVerify="true"` App Links and iOS Associated Domains.
- Serve Android Digital Asset Links from `https://<your-domain>/.well-known/assetlinks.json`.
- Serve the Apple App Site Association file from `https://<your-domain>/.well-known/apple-app-site-association`.
- Add the HTTPS callback URL to the Endurain server and identity-provider allowed redirect/callback URL configuration.

## Local Diagnostics

The app keeps a local diagnostics report to help investigate field issues when a tethered Flutter or Xcode console is not available. Open **Settings > Diagnostics** after relaunching the app to review recent events, captured Flutter/Dart errors, and the raw privacy-filtered report.

Diagnostics are stored only in the app's private support directory and are never uploaded automatically. The report starts with a header naming the app version, build mode, platform, OS version, and device model. It then keeps up to 150 high-level breadcrumbs: app startup and lifecycle (consecutive changes are folded into one entry), screen changes and router redirects, session changes with their reason, token refreshes that failed, failed HTTP requests, single sign-on steps, errors shown to the user, activity recording start/pause/resume/stop, uploads, health sync, point-count milestones, and catchable Flutter/Dart errors.

The report is built to be safe to share. It never records GPS coordinates, the device's name or identifiers, server addresses, or message text from the server. An HTTP request is recorded by endpoint template only (`/api/v1/auth/sessions/:id/tokens`), a route outside the app's own as `unmatched`, and an error by its type, code, and HTTP status. Token-like values, home/container paths, and coordinate-looking strings are also scrubbed before saving. The report is written atomically, so closing the app mid-write cannot corrupt it or turn collection off.

Separately, **opt-in remote crash reporting** can forward captured Flutter/Dart errors to Endurain's managed diagnostics service. It is off by default and fully independent of local diagnostics — the user may enable neither, either, or both. Reporting uses the Sentry protocol and always targets the managed Endurain diagnostics endpoint (`diagnostics.endurain.com`); there is no user-configurable DSN. The same privacy redaction applied to local diagnostics scrubs error payloads before they leave the device, and nothing is transmitted until the user opts in and the managed endpoint is configured in the build.

iOS `.ips` crash reports remain separate system-generated native crash reports. The local diagnostics report complements them by preserving app-side context from before the crash.

## Manual QA Checklists

### Android: Active Recording - Location Provider Loss

Use these steps to validate provider changes on a physical or emulated Android device, in addition to the native service lifecycle tests.

**Prerequisites:** A running Endurain server, a connected Android device with GPS and network location enabled, and developer options active.

1. Open the app and start an activity recording.
2. Verify the foreground-service notification appears and that the recording status is active.
3. Background the app (press Home or the recents button).
4. Open the device Settings and disable **all** location providers (both GPS and network/Wi-Fi scanning). On most devices this is under *Location > App permissions* or by toggling the master location switch.
5. Wait approximately 5–10 seconds for the service to detect the provider change.
6. Return to the app.

**Expected results:**
- The recording reports a failure and retains the collected points.
- Resume and Stop remain available. Resume cannot start collection while permission or location services are unavailable.
- Reopening restores the same session as paused when collection failed. It does not create a completed history entry or upload the interrupted track.
- Stop opens the existing confirmation dialog, with save and discard choices.

**Recovery path:** Re-enable location providers, then resume the existing recording.

### Active Recording Relaunch

1. Start a recording, collect several fixes, then remove the app from recents.
2. Reopen it. A still-running native recorder must remain recording without a new segment or a reset timer. If collection was terminated, it must restart the same session and create a new segment on the next fix.
3. Repeat with an explicitly paused recording. It must stay paused.
4. Repeat before the first GPS fix. The session must not be discarded.
5. Revoke location permission, reopen, and verify the track is retained without an upload. Restore permission and resume, or explicitly stop and save or discard.
6. Stop and save normally. Verify exactly one local activity with the original session ID and connection ownership, and no duplicated points around reconnection.

On iOS, recording works with While Using location access, including with the screen locked; Always access is only needed for iOS to relaunch a terminated app and continue the recording, and a downgrade from Always to While Using keeps the recording going without that recovery. iOS force-quit suppresses background location relaunch until the user opens the app again. Android force-stop and manufacturer battery restrictions can also stop collection. The app preserves the session and restarts when permitted; it cannot reconstruct missing GPS points. Time spent without collection is excluded on restart, using the last persisted fix as the available checkpoint.

## Development Workflow

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

### What CI verifies (and what it does not)

CI runs formatting, Dart analysis, the Dart test suite with a coverage
threshold, the Kotlin unit tests, and a debug Android build. It also builds,
tests and lints the Wear OS app (a separate Gradle build, see
[Wear OS app](#wear-os-app)).

A separate iOS workflow builds the app for the simulator, runs the native
XCTests in `ios/RunnerTests` and the integration tests on a macOS runner. macOS
runners are the most expensive, so it does not run on pull requests: it runs on
pushes to `main` and can be started by hand from the Actions tab
(`workflow_dispatch`) to check a branch before merging. It takes about 15
minutes, so for quicker feedback while changing `ios/**`, build locally first:

```bash
# Compiles the Swift sources, the embedded Apple Watch app and the Xcode
# project configuration. Because of the watch app, a simulator build needs a
# simulator id (see `flutter devices`).
flutter build ios --simulator --debug -d <simulator-id>
```

CI does not sign the app or run it on a device, so check device-only behaviour
(HealthKit, background location, entitlements) on a real iPhone.

Collect coverage and check the minimum line coverage thresholds. The script
applies the exclusion list in `.github/coverage-excludes.txt` (with the reason
for each entry), which CI uses too:

```bash
flutter test --coverage
.github/scripts/check_coverage.sh
```

The Flutter version is pinned in several places (the workflows, the CI builder
image's Dockerfile). `.flutter-version` is the source of truth and CI fails when
a pin drifts from it. After changing the Dockerfile or the Flutter version,
rebuild the CI builder image with the "Build CI builder image" workflow, then
pin the digest it prints in its run summary with
`.github/scripts/pin_ci_image_digest.sh sha256:<digest>`.

Regenerate localization classes after changing ARB files:

```bash
flutter gen-l10n
```

The app ships in 30 languages (listed in `lib/core/localization/app_locales.dart`). The Flutter UI's translations live in `lib/l10n/app_<code>.arb`, with `app_en.arb` as the source; it and `app_pt.arb` carry the `@` metadata, which `l10n.yaml` requires (`required-resource-attributes`). Add every new entry to all 30 files.

Text the operating system shows outside Flutter is translated separately, in the same 30 languages:

- Android phone app (notifications, the Health Connect rationale): `android/app/src/main/res/values-*/strings.xml`. The build generates the Android 13+ per-app language list from these folders (`generateLocaleConfig`).
- Wear OS app: `android/wear/src/main/res/values-*/strings.xml`.
- iPhone permission prompts: `ios/Runner/InfoPlist.xcstrings`.
- Apple Watch app: `ios/EndurainWatch/Localizable.xcstrings` (its screens) and `ios/EndurainWatch/InfoPlist.xcstrings` (its permission prompts).

The native text follows the device language (or, on Android 13+ and iOS, the per-app language set in system settings); the in-app language picker does not change it.

## Building from Source

### iOS

For a local release build:

```bash
flutter build ios --release
```

For TestFlight or App Store Connect, install an Apple Distribution certificate
for the configured development team, then build the signed IPA:

```bash
flutter build ipa --release

# Or with ENDURAIN_CRASH_REPORTING_DSN configuration
flutter build ipa --release \
  --dart-define=ENDURAIN_CRASH_REPORTING_DSN='https://<key>@diagnostics.endurain.com/<project>'
```

Upload `build/ios/ipa/Endurain.ipa` with Transporter or Xcode Organizer. Before
each upload, increment the Flutter build number in `pubspec.yaml`; App Store
Connect requires a unique, increasing build number.

### Apple Watch app

The iOS app embeds a watchOS companion app (`ios/EndurainWatch`, SwiftUI,
watchOS 10 or newer). It records outdoor runs, rides, walks and hikes with an
`HKWorkoutSession`, saves each workout and its route to Health, and hands the
finished session to the iPhone over WatchConnectivity. The iPhone keeps it in
a durable inbox (`ios/Runner/Watch`) until Endurain has stored it as a local
activity, which then uploads like any other; only then is the watch told to
delete its copy. Code shared by both apps (the transfer protocol, the handoff
envelope and the file stores) lives in `ios/Shared/Watch`.

- The watch app's bundle identifier is `com.endurain.endurain.watchkitapp`,
  with the HealthKit capability. Register it for the development team before
  the first signed build or upload.
- It takes its version and build number from `pubspec.yaml`, like the iPhone
  app, so `flutter build ipa` ships both together.
- To run it, open `ios/Runner.xcworkspace` in Xcode and run the
  `EndurainWatch` scheme on a paired watch or a watchOS simulator paired with
  an iPhone simulator.
- Workouts without a GPS route (location denied, or no fix) stay queued on
  both devices, because the server does not accept a GPX without track points
  yet. The watch keeps every workout until the phone confirms it, and sends a
  delivered workout again if the phone has not confirmed it within 10
  minutes, the next time the watch syncs (the phone ignores duplicates).
- Health Sync skips every workout the watch app saved to Health, so a watch
  workout is never imported twice.

### Android

Debug builds do not require release signing credentials:

```bash
flutter build apk --debug
```

Release builds require Android signing configuration. Copy
`android/key.properties.example` to ignored `android/key.properties` and fill it locally, or provide the documented `ANDROID_KEYSTORE_*` environment variables in CI. A release build now fails rather than falling back to the debug key when any signing input is missing.

GitHub Actions release builds require these repository secrets:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded upload keystore.
- `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`: upload-key credentials.
- `ANDROID_UPLOAD_CERT_SHA256`: expected SHA-256 certificate fingerprint, with or without colon separators.

For a published release, tag the commit as `vX.Y.Z+BUILD` mirroring pubspec's `version:` field (for example `v0.8.0+11`). CI splits the tag into the Android `versionName` (`0.8.0`) and `versionCode` (`11`), and fails the build if the tag does not match `pubspec.yaml`. Because Google Play requires a strictly increasing `versionCode`, bump the build number in `pubspec.yaml` before tagging. Manual workflow runs instead require an explicit semantic `version_name` and positive, monotonically increasing `version_code`.

Release builds may also bake in the managed diagnostics DSN for opt-in remote crash reporting. Set the optional GitHub repository **variable** `ENDURAIN_CRASH_REPORTING_DSN` (a Sentry/GlitchTip DSN — a public, send-only client identifier, so it is a variable rather than a secret). CI passes it to the build as `--dart-define=ENDURAIN_CRASH_REPORTING_DSN=...`. It is intentionally not hardcoded in source, so builds from source (forks, F-Droid) omit it and never point crash reports at the Endurain-operated endpoint by default. Remote crash reporting always targets this managed endpoint when the user opts in — there is no user-configurable DSN. When the variable is unset, the build simply ships no managed default and opt-in remote crash reporting stays inactive. For local runs or local/iOS release builds, pass the same flag to `flutter run` or `flutter build`:

```bash
# Run a release build on a connected device with the DSN baked in
flutter run -d <device-id> --release \
  --dart-define=ENDURAIN_CRASH_REPORTING_DSN='https://<key>@diagnostics.endurain.com/<project>'

# Or build a release artifact
flutter build apk --release \
  --dart-define=ENDURAIN_CRASH_REPORTING_DSN='https://<key>@diagnostics.endurain.com/<project>'
```

To avoid repeating long values (and to keep them out of shell history), put your `--dart-define` values in a git-ignored JSON file and pass `--dart-define-from-file=dart-defines.json` instead:

```jsonc
// dart-defines.json (git-ignored)
{
  "ENDURAIN_CRASH_REPORTING_DSN": "https://<key>@diagnostics.endurain.com/<project>"
}
```

```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

`flutter build appbundle` builds the phone app only. A Google Play release
also needs the Wear OS app's bundle; see
[Publishing to Google Play](#publishing-to-google-play).

### Wear OS app

The Wear OS app (`android/wear`, Kotlin, Compose for Wear OS, Wear OS 3 or
newer) records outdoor runs, rides, walks and hikes with Health Services
(GPS, heart rate, distance) and hands each finished session to the phone
over the Wearable Data Layer. The phone app keeps it in a durable inbox
until Endurain has stored it as a local activity, which then uploads like
any other; only then does the watch delete its copy. Code shared by both
apps (the protocol, the handoff envelope and the file stores) lives in
`android/watch_shared`.

It is a standalone Gradle build, so `flutter build apk` never compiles it.
Build it with the phone build's Gradle wrapper (generated by any Flutter
Android build, for example `flutter build apk --config-only`):

```bash
cd android
./gradlew -p wear assembleDebug        # build/outputs/apk/debug in android/wear
./gradlew -p wear testDebugUnitTest lintDebug
```

- It has the same application id as the phone app
  (`com.endurain.endurain`), which the Data Layer requires, and must be
  signed with the same key; release builds read the same `key.properties`
  or `ANDROID_KEYSTORE_*` variables. Upload its release build to a Wear OS
  track of the same Play listing; Play rejects a watch bundle on a phone
  track.
- Its version name follows `pubspec.yaml`; its version code is the Flutter
  build number plus 1,000,000, because Play requires a distinct version code
  for each APK in a release. `-Pendurain.buildName=<name>` and
  `-Pendurain.buildNumber=<number>` override both, like `flutter build`'s
  `--build-name` and `--build-number`.
- The **Build Android** workflow builds it after the phone APK, with the same
  version and upload key, checks both signatures, and attaches it to the
  release as `wear-release.apk`. Install it on a watch with
  `adb -s <watch> install wear-release.apk`, and install the phone app from
  the same release (`app-release.apk`). A phone app from Google Play is
  signed with Google's app-signing key instead of the upload key, so a
  watch app from GitHub cannot connect to it. Install both apps from GitHub,
  or both from Play.
- Workouts without a GPS route stay queued on both devices, because the
  server does not accept a GPX without track points yet. Workouts the phone
  never confirms are dropped from the watch after 90 days.
- Because it is its own Gradle root (`android/wear`), it does not read
  `android/local.properties` or Flutter's JDK setting. If Gradle cannot find
  the Android SDK or a JDK 17, set `ANDROID_HOME` (the `sdk.dir` from
  `android/local.properties`) and `JAVA_HOME`, or add an
  `android/wear/local.properties` with `sdk.dir`.

#### Publishing to Google Play

Google Play takes one bundle per form factor under the same listing. Build
both with the same version (the tag's, or `pubspec.yaml`'s) and the upload
key:

```bash
# Phone app → build/app/outputs/bundle/release/app-release.aab
flutter build appbundle --release \
  --dart-define=ENDURAIN_CRASH_REPORTING_DSN='https://<key>@diagnostics.endurain.com/<project>'

# Wear OS app → android/wear/build/outputs/bundle/release/endurain-wear-release.aab
cd android
./gradlew -p wear bundleRelease \
  -Pendurain.buildName=<version name> -Pendurain.buildNumber=<build number>
```

The `--dart-define` only applies to the Flutter phone app; the watch app is
native Kotlin and has no crash-reporting DSN.

#### Builds without the Wear OS link

The Wearable Data Layer comes from Google Play Services
(`play-services-wearable`). The phone app includes it by default; a Gradle
property leaves it out, and the watch link then reports "unsupported" while
the rest of the app is unchanged:

```bash
flutter build apk --release --android-project-arg=endurain.wearable=false
```

Releases ship one APK, with the Wear OS link. Leaving the link out does not
make the app free of Google Play Services: `geolocator_android` brings
`play-services-location` either way.

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

Activity metadata lives in a SQLite database (`activity.db`, schema v9) under the platform databases directory. The database holds two tables:

| Table                  | Purpose                                                  |
|------------------------|----------------------------------------------------------|
| `schema_version`       | Single-row version counter used to gate migrations.      |
| `local_activity`       | One row per activity, all metadata columns.              |

Each `local_activity` row contains: `id`, `activity_type`, `started_at`, `ended_at`, `elapsed_duration_seconds`, `distance_meters`, `average_speed_meters_per_second`, `max_speed_meters_per_second`, `elevation_gain_meters`, `point_count`, `gpx_file_name`, `upload_status`, `idempotency_key`, `connection_origin`, `connection_profile_id`, `auto_retry_eligible`, `gpx_cleanup_pending`, `created_at`, `updated_at`, `uploaded_at`, `last_upload_attempt_at`, and `last_upload_error_code`. GPX files live on disk under `gpx/` — only the metadata is stored in the database. Health-imported activities are additionally tracked for provenance and de-duplication in a separate `health_import.db` (schema v3).

### Active Recording Recovery Contract

The native recorder owns collection and the private active-session log. Flutter recovery attaches without pausing a live recorder. A stopped recorder restarts only sessions marked `recording`; explicitly paused and failed sessions stay paused until user action. Only a session marked completed or stopping by an explicit Stop is finalized on recovery, preserving interrupted save/upload retries.

Point events carry the local session ID and an offset into the valid persisted-point log. Flutter subscribes before recovery, buffers events during the initial drain, skips replayed offsets, and drains a missing range before accepting later batches. Events from another session are ignored. Channel payload version 2 is shipped together on Dart, Android, and iOS; the durable session and database schemas are unchanged.

On iOS, Dart-owned BLE readings are durably appended to `sensors.jsonl` in the same private active-session directory before being exposed as live values. The log is scoped to the recording ID, restored before rebuilding GPS points, and removed with the recording. Pause, stop, and discard wait for accepted sensor writes; write or read failures retain a recoverable error state instead of reporting success. This preserves readings captured before process termination, but cannot reconstruct measurements never delivered while the app was terminated. Older recordings without a sensor log remain recoverable.

Native tests exercise timing and collection independently of a real GPS receiver. Android uses test-only Robolectric with resources enabled; host-test packaging explicitly depends on Flutter asset generation for the same variant. Run `cd android && ./gradlew :app:testDebugUnitTest` and the iOS `RunnerTests` scheme in addition to `flutter test`.

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
3. Accept the [Contributor License Agreement](CONTRIBUTOR_LICENSE_AGREEMENT.md) in the pull request checklist before the PR can be merged
4. Follow the existing code style and architecture patterns
5. Test on multiple platforms when possible

### Development Guidelines

- **Never hardcode strings** - use `AppLocalizations` (l10n)
- **Use constants** - avoid magic numbers, use files in `core/constants/`
- **Platform-adaptive UI** - use `PlatformUtils` for platform checks
- **Open-source first** - prefer well-maintained open-source dependencies when they meet the need; proprietary or store-specific SDKs are acceptable when their product or platform benefit is clear
- **Follow conventions** - see `.github/copilot-instructions.md`

## License

This project is licensed under the GNU Affero General Public License v3.0
(AGPL-3.0-only). See [LICENSE](LICENSE) for the full terms. AGPLv3 is a strong
copyleft license: anyone distributing modified versions, or operating modified
network-server software, must make the corresponding source available under
AGPLv3 terms. The mobile app itself is distributed software; the related
Endurain server has its own licensing and source-availability obligations.

Accepted external contributions are also subject to the
[Contributor License Agreement](CONTRIBUTOR_LICENSE_AGREEMENT.md), which gives
the Project Owner the additional right to relicense those contributions in
future releases. The Project Owner will preserve the rights already granted to
the public for releases made under AGPLv3.

## Trademark Notice

Endurain® is a trademark of João Vitória Silva.  

You are welcome to self-host Endurain and use the name and logo, including for personal, educational, research, or community (non-commercial) use.  
Commercial use of the Endurain name or logos (such as offering paid hosting, products, or services) is **not permitted without prior written permission**.

See [`TRADEMARK.md`](TRADEMARK.md) for full details.

---

<div align="center">
  <sub>Built with ❤️ from Portugal | Part of the <a href="https://github.com/endurain-project">Endurain</a> ecosystem</sub>
</div>