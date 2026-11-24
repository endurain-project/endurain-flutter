# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Changed

- Updated dependencies: `health` 14.0.0, `sentry` 10.6.0 and `flutter_svg` 2.5.0, plus their transitive updates. Android builds now use Gradle 9.9.2 and Android Gradle Plugin 9.5.2, and the CI builder image and workflows use Flutter 3.50.1 on a refreshed Java 25 base image.

### Fixed

- A passing health-platform read error (rate limit, Health Connect busy, or the iPhone locked) no longer resets Health Sync's connection. With `health` 14 these errors are now reported instead of returning no workouts; only lasting errors still ask the user to reconnect.

## [v0.11.1+21] - 2026-11-24

### Fixed

- Single sign-on now finishes signing in. Flutter's built-in deep linking also handed the SSO callback to the app's router, which sent it to the home screen and closed the login screen before the sign-in could complete. The app now leaves incoming links to `app_links` alone, on Android and iOS.
- Local diagnostics no longer turn themselves off after the app is closed and opened again. Closing the app could interrupt a write of the report, leaving a file the next launch could not read, and the opt-in is stored in that file. The report is now written atomically, so an interrupted write keeps the previous one.

### Added

- A header in the local diagnostics report with the app version, build mode, platform, OS version, and device model, read with `device_info_plus`. The device's name and identifiers are never read into the report.
- More local diagnostics breadcrumbs: each step of a single sign-on, screen changes and router redirects, tab changes, session changes with their reason (signed in, signed out, session ended, unreadable storage), failed token refreshes, failed HTTP requests by endpoint template and status, and every error shown to the user. Failure breadcrumbs now include the error code, HTTP status, and cause instead of only the error type.

### Changed

- The local diagnostics report keeps 150 breadcrumbs instead of 40, and up to 10 errors instead of 8. Consecutive lifecycle changes are folded into one breadcrumb, so a trip to the background no longer pushes out six older entries.
- The diagnostics report format is now version 2, which adds the header.
- Auth, SSO, server settings and API requests share one HTTP client.
- The README documents the `com.endurain.endurain:/auth/sso/callback` address and the diagnostics report's contents.

## [v0.11.0+20] - 2026-11-17

This release requires Endurain server v0.21 or newer, and older app versions cannot sign in to a v0.21 server. If your server sets `ALLOWED_REDIRECT_URIS`, it must include `com.endurain.endurain:/auth/sso/callback` for single sign-on to work.

### Security

- Crash reports sent to Sentry now drop request data, user information, extras and breadcrumbs, and redact event messages and tags, keeping only device, OS, app and runtime context.
- Error text from an SSO sign-in callback is no longer shown to the user, since any app can trigger that deep link. A generic localized error is shown instead, or a specific one when the link carries one of the server's documented failure codes.
- The refresh token is sent in the request body instead of the `Authorization` header, as Endurain v0.21 requires.
- Secure storage is configured with explicit hardened options: Keychain items are available after first unlock and stay on the device, and a transient Android Keystore failure no longer silently erases the stored server and session.

### Fixed

- Remembered heart rate sensors now reconnect reliably on Android. Native Bluetooth addresses are normalized so they match the stored device IDs, and cold starts and returning to the foreground retry the reconnect instead of trying once (#38).
- The configured server URL now survives a secure storage failure or reset thanks to a non-secret mirror. Falling back to the mirror is recorded in diagnostics.
- A missing multi-factor session now shows its own error instead of an unrelated one.
- Activity uploads no longer poll a finished job until they give up and retry, and the app now waits the interval the server asks for between checks.
- Failed uploads and sign-in steps now say why: the file is too large or of an unsupported type, an administrator requires two-step verification the account has not set up, or there were too many sign-in attempts.

### Changed

- Compatibility with Endurain server v0.21: sign-in follows the server's steps (including a second factor after single sign-on), uses the new token exchange route and PKCE form fields, accepts UUID account and provider ids, reads the paged provider list and the renamed public settings route, loads uploaded provider icons, and stores and sends the device id so a sign-in from this app is not reported as a new device each time. Uploads follow the new `/jobs/{id}` API, and an upload refused because the server already has 10 in progress is retried later.
- The single sign-on callback is now `com.endurain.endurain:/auth/sso/callback` on Android and iOS, and the app checks the server allows it before opening the browser. Links to the old `endurain://` address no longer open the app.
- Android release builds no longer need the temporary ProGuard rules. `shared_preferences_android` is now required at 2.5.2 or newer, which ships its own consumer rules.
- Internal restructuring: the app wiring and navigation moved to `lib/app/`, the core services were split into `auth`, `network`, `diagnostics` and `location` packages, and the recording service and map screen were broken into smaller focused components. There are no user-visible changes.
- Stricter lint rules (`avoid_dynamic_calls`, `directives_ordering`, `unnecessary_lambdas`) and sorted imports.
- Updated localized error and health access strings.
- Updated dependencies and raised the minimum to Flutter 3.50.0 (Dart 3.14.0); the CI builder image and workflows use it. Android builds now use Gradle 9.9.1, Android Gradle Plugin 9.5.1 and Kotlin 2.4.21, and the Flutter build image uses Java 25.

### Added

- Activities and health imports saved before the server moved to Endurain v0.21 follow their account to its new id. They are moved silently when the username matches, and the user is asked when it cannot be matched, so queued uploads still go out and no health workout is imported twice.
- A "choose a new password" step at sign-in, for accounts whose password an administrator set.
- Live heart rate from HealthKit during iOS recordings (iOS 26+). Sources such as AirPods Pro 3 now fill heart rate on recorded points; readings from a connected Bluetooth sensor still take priority (#23).
- On-device login flow smoke tests (`integration_test/`), run in CI on an Android emulator and an iOS simulator, plus Dependabot configuration.
- Unit tests for the recording clock, permission gate and sensor session.

## [v0.10.2+19] - 2026-10-21

### Fixed

- Wrong max speed and pace spikes (#11). GPS fixes that imply a speed the activity cannot reach (for example 80 km/h while running), including a poor first fix after a pause, are now dropped before the GPX is uploaded and before on-device stats are computed. Max speed is also taken from a short median window so a single glitch can no longer set it.
- Android release builds getting stuck on a blank splash screen at launch, and language, units, audio and sensor settings failing to load. R8 minification renamed the Kotlin classes that `shared_preferences_android` 2.5 (introduced with v0.10.0) looks up by name over JNI, so every preferences read failed (flutter/flutter#194649). ProGuard rules now keep those classes (temporary, until `shared_preferences_android` 2.5.2 ships its own), a failing or stalled crash-reporting start can no longer prevent the app from starting, and launch no longer waits on the network to confirm a stored session: the session is restored immediately and verified in the background.
- The app no longer hangs on the splash screen when secure storage cannot be read at launch. It starts in guest mode and restores the signed-in session when the storage becomes readable again. Signing in recovers from an unusable store (for example an invalidated Android Keystore key), logout still clears local data when the stored session cannot be read, and queued activity uploads retry instead of failing (#27).

### Changed

- Stronger elevation smoothing (9-sample median, 21-sample moving average) for the elevation gain shown on the device, matching the updated Endurain server so both report the same value (#17).

## [v0.10.1+18] - 2026-10-20

### Fixed

- Added vertical padding to iOS list tiles with subtitles so wrapped subtitle text no longer touches the top and bottom edges (for example in Audio Announcements settings).

## [v0.10.0+17] - 2026-10-20

### Added

- Auto-pause and auto-resume for recordings. Recording pauses automatically when you stop moving and resumes when you start again, with a configurable delay and optional audio announcements (localized).

### Changed

- Compatibility with Endurain v0.20.0: uploads now wait for the server to finish importing the activity before marking it as uploaded, so failed imports are no longer reported as successful. Import errors are shown as localized messages.
- Updated dependencies, including `sentry` 10.1.0 and `universal_ble` 3.1.0.

## [v0.9.2+16] - 2026-10-07

### Fixed

- Reconnect to active native recordings after reopening the app without pausing them or creating a replacement activity. Restart interrupted collection within the same session and keep explicit pauses unchanged.
- Preserve recordings before their first GPS fix and after recorder failures. Failed recordings require an explicit stop before saving or uploading, and remain available for resume or discard.
- Replay persisted and live GPS points once using session-scoped offsets, retain connection ownership, and support retrying local finalization without replacing the recording.
- Preserve captured iOS heart-rate, power, and cadence readings across recording relaunches using a session-scoped durable sensor log.
- Reject unsuccessful iOS recording-state writes instead of acknowledging failed start, pause, resume, or stop transitions.

### Changed

- Show Resume and Stop controls for recoverable failed recordings, and allow the stop confirmation (save or discard) to open for them.
- Updated `cupertino_icons` to 2.0.0, refreshed locked dependencies, and bumped `actions/upload-artifact` to v7.0.2 in the Android APK workflow.
- Added Robolectric-based Android native recorder tests, expanded iOS recorder tests, and documented the active recording recovery contract and manual relaunch QA in the README.

## [v0.9.1+15] - 2026-09-11

### Fixed

- Corrected distance announcement interval options and snapping so 0.5 is available instead of 0.6.
- Prevented an audio announcement preview crash when no `ScaffoldMessenger` is available.
- Aligned Flutter and Dart versions to Flutter 3.47.3 and Dart 3.13.3 across the app, Docker builder, and CI workflows.

## [v0.9.0+14] - 2026-09-04

### Added

- Added configurable activity auto-pause and auto-resume with movement detection, resume hysteresis, and process-recovery support.
- Added localized, on-device audio announcements for distance or elapsed-time milestones during foreground and background activity recording, including distance, duration, lap plus overall pace or speed, and automatic pause or resume cues.
- Added audio announcement settings with a master switch, per-activity enablement and distance/time intervals, metric/imperial defaults, optional audio ducking, and an audible per-activity preview.
- Added durable milestone tracking and privacy-safe native failure logging so delayed updates and recorder restarts do not replay stale milestones, while speech failures cannot interrupt activity recording.
- Added a contributor license agreement, pull request attestation, and required-status workflow for relicensing rights over accepted external contributions.

## [v0.8.2+13] - 2026-08-30

### Fixed

- Unified the duration shown in completion, history, and activity details, and calculated running pace from total time over distance.
- Kept the HealthKit connection marker device-local so restored preferences cannot be mistaken for authorization on another device.

### Changed

- Moved the "keep uploaded GPX files" and health auto-sync settings out of the platform keychain into the regular preference store. These two preferences reset to their defaults once on upgrade.
- Updated `go_router` to 18.0.0, `material_ui` to 1.1.0, `cupertino_ui` to 1.0.1, and `androidx.core:core-ktx` to 1.19.0.

### Security

- Added build-time managed-cloud HTTPS policy and tile-server host allowlist configuration, with Android and iOS transport-policy parity checks.

## [v0.8.1+12] - 2026-08-26

### Fixed

- Activity metrics calculations, including elevation, speed, and average speed, with expanded test coverage.

### Changed

- Updated `flutter_secure_storage` to 11.0.0 and adjusted Android SDK compile options accordingly.
- Updated the Android Gradle Plugin to 9.1.1 and the Android platform/`compileSdk` version, with related Dockerfile updates for additional platform support.

## [v0.8.0+11] - 2026-08-21

### Changed

- Upgraded to Flutter 3.47.x and migrated the adaptive UI layer to the `material` and `cupertino` design libraries.
- Updated localization delegates and test imports to match the migration.
- Removed the unused `Podfile` and related CocoaPods configuration.
- Cleaned up build configuration, dependencies, and Dockerfile comments/directory naming.

### Fixed

- `flutter_secure_storage_darwin` checksum in `Podfile.lock`.
- Release tagging logic in the CI workflow.

## [v0.7.3+10] - 2026-08-12

### Fixed

- Diagnostics remote-enable subtitle localization consistency across languages.

### Changed

- Added `.dockerignore` and updated the CI workflow to respect it.

## [v0.7.2+9] - 2026-08-12

### Added

- `AdaptiveListTileSubtitle` widget for consistent subtitle styling in adaptive list tiles.
- `DeviceMeasurementSystemChannel` for locale-based measurement system (metric/imperial) resolution.

### Fixed

- Device measurement system service integration with app infrastructure.

## [v0.7.1+8] - 2026-08-11

### Added

- Imperial units support.
- CI workflows for validating Conventional Commits and building the CI Docker image.
- `FUNDING.yml`.
- GitLab mirror workflow for repository synchronization.

### Fixed

- Recording blockers preventing activity recording in certain conditions (#14).
- Missing `ITSAppUsesNonExemptEncryption` key and unclear HealthKit usage description in `Info.plist`.
- GitHub repository/GPX documentation links after migrating the project from Codeberg to GitHub.

### Changed

- Updated Android build configuration and Dockerfile for improved compatibility.
- Migrated project URLs and localization strings from Codeberg to GitHub.

## [v0.7.0+7] - 2026-07-23

### Added

- Remote crash diagnostics with opt-in reporting (#13).

## [v0.6.0+6] - 2026-07-21

### Added

- Recording of power and cadence from external Bluetooth sensors (#12).

## [v0.5.2+5] - 2026-07-20

### Added

- Health Connect permissions and enhanced health data handling.

## [v0.5.1+4] - 2026-07-19

### Added

- Autofill support in the login form.

## [v0.5.0+3] - 2026-07-17

### Added

- Bluetooth heart rate sensor support (#11).

## [v0.4.0+2] - 2026-07-15

### Added

- Richer post-recording activity summary, persisted metrics, and route map (#10).

### Fixed

- `apksigner` path resolution using `ANDROID_SDK_ROOT` in the Android release workflow.

## [v0.3.0+1] - 2026-07-14

### Added

- Health data integration (read/write) with permission handling.
- Regression tests for Android 15 edge-to-edge enforcement in `AdaptiveScaffold`.
- Guest recordings now bind to the active connection on sign-in.

### Changed

- Modernized the Android CI pipeline and enhanced the Android release workflow with version inputs and signing checks (#9).

### Fixed

- CI runner memory tuning for build stability.
- Profile fetch retry after PKCE token exchange.

## [v0.2.0] - 2026-06-29

### Added

- Language selection with locale persistence, including European Portuguese and additional language support.
- Offline guest mode and session management.
- Diagnostics on/off switch with translations.
- Comprehensive tests for map features and settings.

### Changed

- `CupertinoListSection` now uses a transparent background.

## [v0.1.0] - 2026-06-01

### Added

- Core activity recording: GPS tracking, stats calculation, GPX generation, and direct upload to the Endurain server.
- Background location tracking during recording, including low-accuracy fix filtering on Android.
- Local SQLite-backed activity store (`SqfliteActivityStore`) with pagination, migration from the legacy manifest format, and schema versioning.
- Durable upload recovery with retry and idempotency handling, including automatic retries on app resume and network restoration.
- GPX export/share for recorded activities.
- Diagnostics screen with local report sections.
- Adaptive UI components (Material/Cupertino) for cross-platform consistency.
- Managed transport policy: rejects insecure HTTP and validates tile-server/API hosts in managed deployments.
- CI workflows for automated builds, Android APK signing, and a prebuilt Docker builder image.

### Fixed

- Distance creep across paused recording segments in `ActivityStatsCalculator`.
- Various secure storage, refresh-token, and Android provider-disabled recording edge cases.
- iOS share sheet position origin for the GPX share sheet.

### Security

- Bound `ApiResponse.errorDetail` to prevent arbitrary server text from being rendered in the UI.
- Single-flight refresh token mechanism in `AuthService`.

## [v0.0.1] - 2025-12-11

### Added

- Initial Flutter mobile app scaffold for Endurain, including SSO/PKCE authentication, server settings, and README documentation.
