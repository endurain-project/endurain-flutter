# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added configurable on-device audio announcements for distance and time milestones, with activity-specific metric/imperial defaults, lap and overall pace or cycling speed, background playback, optional audio ducking, and stale-milestone suppression.
- Added a per-activity audio announcement preview so a missing or muted device speech engine is detectable from settings instead of only during a recording.

### Changed

- Reduced background recording I/O by checkpointing audio-announcement progress instead of rewriting it for every location update.
- Added privacy-safe native diagnostics for text-to-speech failures while keeping announcements isolated from activity recording.

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
