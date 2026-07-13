# Health Platform Integration — Architecture & Implementation Plan

Status: proposed (not yet implemented) — reviewed and corrected 2026-06-10
Scope: Apple HealthKit (iOS) + Health Connect (Android, including Samsung
Health and other wearables) as a **new source of activities** that feeds the
existing local-storage + upload pipeline.

---

## 1. Goal

Let users import workouts recorded by their wearables — Apple Watch, Samsung /
Galaxy Watch, Garmin, Fitbit, Wear OS, etc. — into Endurain, so those activities
are uploaded to their Endurain server the same way GPS recordings already are.

We achieve this with a **single platform abstraction** backed by two operating
system APIs:

| Platform | OS API | What it gives us | FOSS / F-Droid |
|----------|--------|------------------|----------------|
| iOS | Apple **HealthKit** | Apple Watch workouts: type, start/end, distance, energy, heart rate, GPS route (via `HKWorkoutRouteQuery`) | iOS-only; never enters the F-Droid (Android) build |
| Android | **Health Connect** (`androidx.health.connect:connect-client`, Apache 2.0) | Workouts written by Samsung Health, Garmin, Fitbit, Wear OS, etc. | Library is open source — see F-Droid nuance in §2 |

Key insight: **Samsung Health and Google Fit both write into Health Connect.**
We read wearable data *through* Health Connect and **never** touch the
proprietary Samsung Health Data SDK or the deprecated Google Fit API.

### Explicitly out of scope / avoided
- **Direct Samsung Health Data SDK** — proprietary, partner-approval gated,
  closed-source. Not used. Samsung data arrives via Health Connect instead.
- **Google Fit API** — proprietary *and* shutting down (2026). Not used.
- These exclusions are what keep the Android build F-Droid compatible.

---

## 2. F-Droid compatibility & the feature flag

**F-Droid compatibility is preserved for the library layer.** The
`androidx.health.connect:connect-client` Jetpack library (Apache 2.0) contains
no proprietary blobs and no Google Play Services dependency — confirmed by
auditing the package's `android/build.gradle` transitive dep tree. HealthKit
code is compiled for iOS only and never enters the Android / F-Droid build.

### The recommendation
Keep a feature flag, but **default it to `true` for all builds including
F-Droid.** The flag is a *safety / rollout mechanism*, **not** an F-Droid
exclusion switch:

- `AppConfig.healthSyncEnabled` defaults to `true`.
- The composition root (`main.dart`) allows a compile-time override via
  `bool.fromEnvironment('ENABLE_HEALTH_SYNC', defaultValue: true)`.
- F-Droid builds ship with the flag **on** — full Health Connect functionality.
- Whether the feature actually *does* anything at runtime is decided by a
  separate **runtime availability check** (`getSdkStatus()`), not by the build.

### Benefits that have nothing to do with excluding F-Droid
- **Kill switch** — if Health Connect causes a crash on some device, you can
  ship a build with `--dart-define=ENABLE_HEALTH_SYNC=false` without reverting
  code.
- **Clean degradation** — forces a proper "off" code path so the rest of the
  app (GPS recording, manual upload) keeps working when health sync is disabled.
- **Testing** — disable it in unit/widget tests that should not touch native
  health APIs.

### The genuinely device-dependent part — and the F-Droid honest caveat
On **Android 14+**, Health Connect is an AOSP Mainline module (`HealthFitness`)
built into the OS. De-Googled ROMs (GrapheneOS, CalyxOS) ship it — full
functionality even without Play Services.

On **Android 9–13**, Health Connect is a Play-Store-only proprietary APK that
officially requires Google Play Services. The `health` package's
`installHealthConnect()` opens the Play Store, which will not exist on a
de-Googled device. The `androidx.health.connect:connect-client` *library* is
clean, but the *runtime service* is not. **Accurate F-Droid claim: full
Health Connect functionality is guaranteed on Android 14+; on Android 9–13
with a de-Googled ROM, the feature degrades to "not available"** — which the
existing `HealthSdkStatus.unsupported` path handles cleanly.

The same APK handles both scenarios via the runtime `getSdkStatus()` check.

---

## 3. Architecture decision

The cleanest fit with the existing codebase is to treat **health as a new
*source* of activities that feeds the existing upload pipeline** rather than a
parallel system. We reuse, unchanged:

- `LocalActivityRepository` — persists a GPX file + a `LocalActivityRecord`
  (sqflite) with `uploadStatus = pending`.
- `ActivityUploadService` — multipart GPX upload to
  `POST /api/v1/activities/create/upload`, with the `Idempotency-Key` header.
- `ActivityUploadQueue` — app-lifetime, connectivity-/resume-triggered,
  single-flight drainer that retries pending/failed uploads.

A health workout becomes a GPX file and enters that pipeline like any recording.
This gives us durable storage, retry, idempotency, and connectivity handling
**for free**, with no duplication.

### Why an abstraction over a Flutter package (not native channels)
The existing background GPS recorder uses native channels because background
location collection must run in a platform foreground service. **Health reading
is on-demand and foreground**, so a Flutter plugin is the appropriate tool. We
wrap the `health` package (BSD-2, F-Droid safe) behind an abstract
`HealthPlatformAdapter` — mirroring the existing
`LocationPlatformAdapter` / `GeolocatorLocationPlatformAdapter` seam. Consumers
depend only on the abstraction, so:

- it is fully testable with a fake adapter (no native calls in tests), and
- if we ever need to drop to native HealthKit / Health Connect channels, we swap
  the concrete adapter **without touching any consumer**.

### Component map (all new code lives under `lib/features/health/`)

```text
lib/features/health/
├── models/
│   ├── health_sdk_status.dart            # available / needsProviderInstall / unsupported
│   ├── health_authorization_status.dart  # granted / denied / notDetermined
│   ├── health_workout_type.dart          # maps OS workout type -> ActivityType
│   ├── health_route_point.dart           # lat/lon/elevation/time/heartRate
│   ├── health_workout.dart               # one imported workout (metadata + route)
│   └── health_sync_state.dart            # controller-facing state snapshot
├── repositories/
│   ├── health_import_store.dart          # abstract: dedup + last-sync cursor
│   ├── sqflite_health_import_store.dart   # concrete sqflite implementation
│   ├── health_import_repository.dart     # facade over the store
│   └── health_sync_settings_repository.dart # user opt-in + auto-sync toggle
├── services/
│   ├── health_platform_adapter.dart      # abstract adapter + Unsupported impl
│   ├── health_package_platform_adapter.dart # concrete, uses `health` pkg
│   ├── health_workout_gpx_builder.dart   # workout -> GPX (route + HR extension)
│   └── health_sync_service.dart          # orchestration
├── controllers/
│   └── health_sync_controller.dart       # ChangeNotifier for the UI
├── screens/
│   └── health_sync_screen.dart           # status / authorize / list+select / import
└── widgets/                              # smaller UI pieces as needed
```

### Import model — user reviews and selects what to import
Import is **not** an all-or-nothing bulk push. The flow is two phases:

1. **Preview (read-only).** The screen asks the service to *list* importable
   workouts in a lookback window. Nothing is written, nothing is uploaded — the
   user just sees the candidate workouts (type, date, distance, duration,
   whether a GPS route is present) with each already-imported one excluded.
2. **Selective import.** The user picks **one, several, or all** candidates and
   confirms. Only the chosen workouts are converted to GPX, persisted as
   `pending` records, and enqueued for upload.

This keeps the user in control (they may not want every Apple Watch / wearable
workout on their Endurain server) while still allowing a one-tap "select all".
An optional auto-sync-on-resume path (Phase N) reuses the same service to import
**all** new candidates without prompting, for users who explicitly opt in.

### Data flow

```mermaid
flowchart LR
  A[HealthPlatformAdapter] -->|readWorkouts in lookback window| B[HealthSyncService.listImportable]
  B -->|filter route + drop already-imported| H[HealthSyncState.importableWorkouts]
  H -->|user selects 1..n| U{User confirms}
  U -->|importSelected sourceIds| I[HealthSyncService.importWorkouts]
  I -->|map type, build GPX| C[HealthWorkoutGpxBuilder]
  C --> D[LocalActivityRepository]
  D -->|record pending| E[ActivityUploadQueue]
  E --> F[ActivityUploadService -> Endurain server]
  I -->|mark imported| G[HealthImportRepository]
```

### Deduplication
Each OS workout has a stable UUID. We persist imported UUIDs in
`HealthImportStore`, and the preview always excludes workouts whose `sourceId`
is already imported — so a workout the user skipped stays in the candidate list
until they either import it or it ages out of the lookback window, while an
already-imported one never reappears. The workout UUID is also used to derive
the `Idempotency-Key`, so even if a record is re-imported the server de-dupes
it. `lastSyncAt` is recorded for display and as the auto-sync window start; it
is **not** used to hide unimported candidates (dedup is purely by the imported
`sourceId` set, which is what makes partial/selective import correct).

### Heart rate & metrics
Route points carry heart rate where available; the GPX builder writes it using
the standard `gpxtpx:TrackPointExtension` (`<gpxtpx:hr>`), so Apple Watch / wearable
HR survives the import.

### Scope of v1 (important honesty about the backend)
The Endurain upload endpoint accepts **GPX**, which requires track points.
**v1 imports GPS-based outdoor workouts** (runs, rides, walks, hikes — exactly
the Apple Watch / wearable case the user asked about). Indoor / no-route workouts
(e.g. treadmill) are **deferred** until a structured (non-GPX) ingest path
exists. In the preview list they are shown as **non-importable** (greyed out /
not selectable, with a short reason) rather than silently dropped, so the user
understands why they cannot be selected. This is documented as a known
limitation rather than worked around with a malformed GPX.

---

## 4. Platform configuration required

### Android (Health Connect)
- `minSdk` must be **≥ 26**. Currently `minSdk = flutter.minSdkVersion`; verify
  Flutter's default for this SDK is ≥ 26 and pin explicitly if not.
- `AndroidManifest.xml`:
  - Read permissions, e.g. `android.permission.health.READ_EXERCISE`,
    `READ_HEART_RATE`, `READ_DISTANCE`, `READ_TOTAL_CALORIES_BURNED`,
    `READ_STEPS` (only those we actually use).
  - A **permissions-rationale** activity + intent-filter
    (`androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE`) — required by Health
    Connect policy.
  - A `<queries>` entry for the Health Connect package so the app can detect /
    launch it on Android < 14.

### iOS (HealthKit)
- Add the **HealthKit capability** in Xcode (creates `Runner.entitlements`).
- `Info.plist`: `NSHealthShareUsageDescription` (read). Add
  `NSHealthUpdateUsageDescription` only if we ever write back (not in v1).
- Requires an Apple Developer account to enable the entitlement; App Store review
  will ask us to justify the health data usage.

---

## 5. Implementation plan

Each **step** below is sized to roughly **15 minutes to implement and review**.
Steps are ordered so every dependency exists before it is used. Do them in
order; do not start a step until the previous one's acceptance check passes.

Conventions to follow in **every** step (from `.github/copilot-instructions.md`
and `endurain-scalable-mobile.instructions.md`):
- `snake_case` file names; feature code under `lib/features/health/`.
- `const` constructors and `final` wherever possible; trailing commas; ≤ 80 cols.
- **No hardcoded user-facing strings** — use `AppLocalizations` (`l10n`).
- Services surface `AppException(AppErrorCode...)`, never raw errors; **never log
  coordinates, file paths, or any PII** (sanitized diagnostics breadcrumbs only).
- Feature code obtains services via `AppScope.servicesOf(context)`, **never**
  `AppServices.instance` (guarded by
  `test/architecture/app_services_instance_guard_test.dart`).
- After each code step run, as applicable: `flutter analyze`, `dart format .`,
  and the relevant tests. The repo enforces a **75% overall line coverage /
  60% per-file minimum** (see `tool/check_coverage.dart` and `CONTRIBUTING.md`).

> Commands reference
> - Analyze: `flutter analyze`
> - Format: `dart format .`
> - Tests (all): `flutter test`
> - Tests (one file): `flutter test test/path/to/file_test.dart`
> - Regenerate localizations: `flutter gen-l10n`
> - Coverage gate: `flutter test --coverage` then `dart run tool/check_coverage.dart`

---

### Phase A — Feature flag & configuration plumbing ✅

**Step A1 — Add `healthSyncEnabled` to `AppConfig`.** ✅
- File: `lib/core/config/app_config.dart`.
- `AppConfig` is a `const`-constructible class with `AppConfig.defaults` as the
  single static instance. Add a `final bool healthSyncEnabled;` field with
  `this.healthSyncEnabled = true` in the const constructor. Add a doc comment
  explaining it is a safety/rollout flag that defaults on for **all** builds
  including F-Droid, and that runtime availability is decided separately.
- Acceptance: `flutter analyze` clean; `AppConfig.defaults.healthSyncEnabled` is
  `true`. No behavior change anywhere yet.

**Step A2 — Allow compile-time override in the composition root.** ✅
- File: `lib/main.dart`.
- Currently `main.dart` calls `AppServices()` with no config argument — it uses
  `AppConfig.defaults` internally. Change this to pass an explicit config:
  `AppServices(config: const AppConfig(healthSyncEnabled: bool.fromEnvironment('ENABLE_HEALTH_SYNC', defaultValue: true)))`.
  Update `AppServices` to accept and store the config if it does not already.
- Add a short test in `test/core/config/` asserting the field round-trips
  (default true; explicit false honored).
- Acceptance: building with `--dart-define=ENABLE_HEALTH_SYNC=false` disables the
  flag; default build keeps it `true`. Analyze + test pass.

---

### Phase B — Domain models (pure Dart, no plugins; trivial to unit test) ✅

**Step B1 — `HealthSdkStatus` enum.** ✅

**Step B2 — `HealthAuthorizationStatus` enum.** ✅

**Step B3 — `HealthWorkoutType` mapping to `ActivityType`.** ✅

**Step B4 — `HealthRoutePoint` model.** ✅

**Step B5 — `HealthWorkout` model.** ✅

**Step B6 — `HealthSyncState` model (controller-facing snapshot).** ✅
- File: `lib/features/health/models/health_sdk_status.dart`.
- Values: `available`, `needsProviderInstall` (Android < 14, Health Connect app
  missing), `unsupported` (platform/version cannot do it).
- Acceptance: analyze clean; trivial test verifying the values exist.

**Step B2 — `HealthAuthorizationStatus` enum.**
- File: `lib/features/health/models/health_authorization_status.dart`.
- Values: `granted`, `denied`, `notDetermined`.
- Acceptance: analyze clean.

**Step B3 — `HealthWorkoutType` mapping to `ActivityType`.**
- File: `lib/features/health/models/health_workout_type.dart`.
- An enum (or const map) mapping OS workout categories (running, cycling,
  walking, hiking, other) to the existing
  `ActivityType` (`lib/features/activity/models/activity_type.dart`), with an
  `other` fallback — mirror `ActivityType.fromApiValue`'s fallback style.
- Test: every mapped case returns the expected `ActivityType`; unknown -> `other`.
- Acceptance: analyze + test pass.

**Step B4 — `HealthRoutePoint` model.**
- File: `lib/features/health/models/health_route_point.dart`.
- Immutable: `latitude`, `longitude`, `DateTime time`, nullable `elevation`,
  nullable `heartRate`. `const` constructor, `final` fields.
- Acceptance: analyze clean; small construction test.

**Step B5 — `HealthWorkout` model.**
- File: `lib/features/health/models/health_workout.dart`.
- Immutable: `sourceId` (OS UUID), `HealthWorkoutType type`, `DateTime startedAt`,
  `DateTime endedAt`, nullable `distanceMeters`, nullable `energyKilocalories`,
  `List<HealthRoutePoint> route`. Add `bool get hasRoute => route.isNotEmpty;`.
- Acceptance: analyze clean; construction test incl. `hasRoute`.

**Step B6 — `HealthSyncState` model (controller-facing snapshot).**
- File: `lib/features/health/models/health_sync_state.dart`.
- Immutable snapshot: `HealthSdkStatus sdkStatus`, `HealthAuthorizationStatus
  authStatus`, `bool isLoadingWorkouts` (preview in progress), `bool isImporting`
  (selected import in progress), `List<HealthWorkout> importableWorkouts` (the
  preview candidates, route-bearing and not yet imported), `Set<String>
  selectedSourceIds` (the user's current selection), nullable `DateTime
  lastSyncAt`, `int importedCount` (last import run), `int
  routeConsentDeniedCount` (workouts skipped on Android because the user has not
  granted "Always allow" for third-party exercise routes — used by the screen to
  surface guidance), nullable `AppException error`. Provide a `copyWith` (follow
  the `copyWith` style used in activity models, e.g.
  `local_activity_record.dart`). Default `importableWorkouts` to `const []` and
  `selectedSourceIds` to `const {}`.
- Acceptance: analyze clean; `copyWith` test covering selection mutations.

---

### Phase C — Error codes & localization (needed before services that throw) ✅

**Step C1 — Add health `AppErrorCode` values.**
- File: `lib/core/models/app_exception.dart`.
- Add (keep the enum alphabetical-ish like the existing list):
  `healthUnavailable`, `healthPermissionDenied`, `healthReadFailed`,
  `healthImportFailed`, `healthGpxBuildFailed`.
- Acceptance: analyze clean.

**Step C2 — Localize the new error codes.**
- Files: `lib/core/utils/error_localizations.dart`, `lib/l10n/app_en.arb`,
  `lib/l10n/app_pt.arb`.
- Add a `case` for each new code mapping to a localized message; add matching ARB
  entries in **both** en and pt under the appropriate section, each with a
  `description` noting usage (`"Used in: error_localizations.dart"`). Follow the
  existing `errorXxx` / `errorXxxWithDetails` naming used for other codes.
- Run `flutter gen-l10n`.
- Acceptance: `flutter gen-l10n` succeeds; analyze clean; an `app_exception` /
  error-localization test covers the new codes (mirror existing test patterns).

---

### Phase D — Platform adapter abstraction (still no plugin dependency) ✅

**Step D1 — Define the abstract `HealthPlatformAdapter`.**
- File: `lib/features/health/services/health_platform_adapter.dart`.
- Abstract methods (all `Future`):
  - `Future<HealthSdkStatus> getSdkStatus();`
  - `Future<HealthAuthorizationStatus> requestAuthorization();`
  - `Future<HealthAuthorizationStatus> currentAuthorizationStatus();`
  - `Future<List<HealthWorkout>> readWorkouts({required DateTime start, required DateTime end});`
- Doc-comment the contract: implementations must surface failures as
  `AppException` (`healthReadFailed`, etc.) and must never log coordinates/PII.
- Acceptance: analyze clean.

**Step D2 — `UnsupportedHealthPlatformAdapter` (graceful "off" path).**
- Same file (or `unsupported_health_platform_adapter.dart`).
- Implements the abstract adapter returning `HealthSdkStatus.unsupported`,
  `HealthAuthorizationStatus.denied`, and an empty workout list. Used on the
  host/test runtime and any non-iOS/Android platform — this is the clean
  degradation path.
- Test: every method returns the unsupported/empty values without throwing.
- Acceptance: analyze + test pass.

**Step D3 — Add a reusable fake adapter for tests.**
- File: `test/features/health/fakes/fake_health_platform_adapter.dart` (or under
  `test/helpers/`).
- Configurable fake: programmable sdk status, auth status, and a canned workout
  list; records calls so services can be tested without native code.
- Acceptance: analyze clean (the fake compiles under `flutter test`).

---

### Phase E — Add the `health` package & the concrete adapter ✅

> **API shape note (as of `health` ≥ 13.3.0):** GPS routes are a separate
> `HealthDataType.WORKOUT_ROUTE` query returning `WorkoutRouteHealthValue`
> objects correlated to workouts by `workoutUuid` — they are **not** embedded
> inside `WORKOUT` data points. Heart rate is a separate `HEART_RATE` time-range
> query that must be merged onto route points by timestamp. Steps E3–E5 reflect
> this three-query structure; do not collapse them into one step.

**Step E1 — Add the `health` dependency.**
- File: `pubspec.yaml`.
- Add `health: ^13.3.1` (or the latest ≥ 13.3.0 — route support on both
  platforms landed in 13.3.0) under dependencies with a comment noting it is
  **MIT-licensed** and F-Droid-library-safe (uses `androidx.health.connect`,
  no Google Play Services artifacts in the library). Run `flutter pub get`.
- Acceptance: `flutter pub get` succeeds; `flutter analyze` clean. Confirm the
  resolved transitive deps do **not** pull Google Play Services / Firebase
  (spot-check the Android dependency tree with `./gradlew dependencies`).

**Step E2 — Implement `HealthPackagePlatformAdapter` — status & auth.**
- File: `lib/features/health/services/health_package_platform_adapter.dart`.
- Implement `getSdkStatus`, `requestAuthorization`, `currentAuthorizationStatus`
  using the `health` package. Map the package's status/permission results to our
  `HealthSdkStatus` / `HealthAuthorizationStatus`. Wrap any plugin error as
  `AppException(AppErrorCode.healthUnavailable / healthPermissionDenied)`.
- Inject the `Health` instance (or a thin function) via the constructor so it can
  be substituted in tests.
- Acceptance: analyze clean; unit test with an injected fake `health` seam covers
  the status/auth mapping (no real native calls).

**Step E3 — Implement `HealthPackagePlatformAdapter.readWorkouts` — workout fetch.**
- Same file.
- Query `HealthDataType.WORKOUT` records in `[start, end]` and map each into a
  `HealthWorkout` skeleton (type, startedAt, endedAt, distance, energy). Skip
  records we can't map; wrap failures as `AppException(healthReadFailed)`.
- Acceptance: analyze clean; unit test: a workout record maps correctly; an
  unmapped type falls back to `HealthWorkoutType.other`.

**Step E4 — Implement route correlation in `HealthPackagePlatformAdapter`.**
- Same file.
- The `health` package exposes GPS routes via `HealthDataType.WORKOUT_ROUTE`
  as **separate data points** each carrying a `WorkoutRouteHealthValue` list of
  `WorkoutRouteLocation` (lat/lon/altitude/timestamp), correlated to workouts by
  `workoutUuid`. Query `WORKOUT_ROUTE` for the same window, group by UUID, merge
  each route onto the matching `HealthWorkout`. Points not matching any workout
  UUID are discarded.
- **Android caveat:** reading routes recorded by *other* apps (Samsung Health,
  Garmin, etc. — the primary v1 target) may return `ConsentRequired` rather
  than route data. The adapter must detect and handle this:
  - If `ConsentRequired` is returned for a workout, mark that workout as having
    `hasRoute == false` and record a sanitized breadcrumb noting why it was
    skipped. Do **not** throw; the workout may still be importable metadata-only
    in a future version.
  - The health sync screen (Phase M) must surface this condition with guidance:
    "To import routes from [app], open Health Connect → Permissions → [app] →
    'Always allow' for exercise routes."
  - Add a `routeConsentDeniedCount` field to `HealthSyncState` for the UI to
    display.
- **iOS:** routes are read via the same `WORKOUT_ROUTE` type backed by
  `HKWorkoutRouteQuery` — no consent quirk.
- Acceptance: unit test with fake data: GPS workout with route merges correctly;
  `ConsentRequired` workout produces `hasRoute == false` without throwing.

**Step E5 — Implement heart-rate merge in `HealthPackagePlatformAdapter`.**
- Same file.
- Heart rate is a **separate time-range query**: `HealthDataType.HEART_RATE` for
  the same `[start, end]` window. For each route point, find the nearest HR
  sample by timestamp (within a ± 5 s tolerance) and attach it to the
  `HealthRoutePoint`. HR samples with no nearby route point are discarded.
- Acceptance: unit test: a route point within 5 s of an HR sample gets `heartRate`
  populated; one outside tolerance does not.

---

### Phase F — Workout → GPX ✅

**Step F1 — Review and, if needed, extract a shared GPX writer.**
- File: `lib/features/activity/services/activity_gpx_builder.dart`.
- Read it. If the metadata/track-point writing helpers can be cleanly reused,
  extract the shared XML-writing bits into a small helper that both
  `ActivityGpxBuilder` and the new health builder can call. If extraction is not
  clean, do **not** force it — duplicate the minimal escaping/format helpers
  instead and note why. (Avoid over-engineering.)
- Acceptance: existing activity GPX tests still pass; analyze + format clean.

**Step F2 — Implement `HealthWorkoutGpxBuilder`.**
- File: `lib/features/health/services/health_workout_gpx_builder.dart`.
- `String build(HealthWorkout workout)`: emit GPX with metadata (name/time/type
  from the mapped `ActivityType.apiValue`), one `<trkseg>`, and a `<trkpt>` per
  route point including `<ele>`, `<time>`, and `<extensions><gpxtpx:TrackPointExtension>
  <gpxtpx:hr>` when heart rate is present. Reuse the escaping/format helpers from
  F1.
- Acceptance: unit test asserting the GPX contains the expected track points,
  type, and an `hr` extension when present; valid XML structure.

---

### Phase G — Import state (dedup + sync cursor) ✅

**Step G1 — Define the abstract `HealthImportStore`.**
- File: `lib/features/health/repositories/health_import_store.dart`.
- Abstract methods: `Future<bool> isImported(String sourceId);`,
  `Future<void> markImported({required String sourceId, required String localActivityId});`,
  `Future<DateTime?> lastSyncAt();`, `Future<void> setLastSyncAt(DateTime at);`.
- Doc the contract (AppException on IO failure; no PII).
- Acceptance: analyze clean.

**Step G2 — Implement `SqfliteHealthImportStore`.**
- File: `lib/features/health/repositories/sqflite_health_import_store.dart`.
- Mirror `SqfliteActivityStore` exactly: a `_migrations` map keyed by target
  version, `_runMigrations(from, to)` invoked from both `onCreate` and
  `onUpgrade`, a single-row schema-version table. Table: imported workouts
  (`source_id` PK, `local_activity_id`, `imported_at`); store `last_sync_at` in a
  small key/value row or its own table.
- Acceptance: unit test (sqflite ffi in tests, as the activity store tests do):
  mark + isImported round-trips; last-sync persists across reopen; schema version
  recorded.

**Step G3 — `HealthImportRepository` facade.**
- File: `lib/features/health/repositories/health_import_repository.dart`.
- Thin facade over the store (constructor takes a `HealthImportStore`; defaults to
  the sqflite impl), matching how `LocalActivityRepository` wraps its store. This
  is the type services depend on.
- Acceptance: analyze clean; a small pass-through test.

---

### Phase H — Settings (user opt-in) ✅

**Step H1 — `HealthSyncSettingsRepository`.**
- File: `lib/features/health/repositories/health_sync_settings_repository.dart`.
- Mirror `ActivityRetentionSettingsRepository`: keys for `health_sync_enabled`
  (user opt-in, default `false` — user must explicitly connect) and
  `health_auto_sync_on_resume` (default `false`). Backed by
  `SecureStorageService`.
- Acceptance: analyze clean; round-trip test.

---

### Phase I — Orchestration service ✅

**Step I1 — `HealthSyncService` skeleton + availability gate.**
- File: `lib/features/health/services/health_sync_service.dart`.
- Constructor injects: `HealthPlatformAdapter`, `HealthImportRepository`,
  `LocalActivityRepository`, `ActivityUploadQueue`, `HealthWorkoutGpxBuilder`,
  `HealthSyncSettingsRepository`, `DiagnosticsRecorder`, and a `bool
  healthSyncEnabled` (the config flag) plus a `DateTime Function() now` seam.
- Add `Future<HealthSdkStatus> status()` and an internal guard that short-circuits
  when the config flag is off (returns a clean "disabled" result, no native call).
- Acceptance: analyze clean; test: flag off ⇒ no adapter calls.

**Step I2 — `HealthSyncService.requestAccess()`.**
- Delegate to the adapter's authorization request; surface
  `AppException(healthPermissionDenied)` on denial. Record a sanitized breadcrumb.
- Acceptance: analyze clean; test using the fake adapter (granted vs denied).

**Step I3 — `HealthSyncService.listImportable()` — preview only, no writes.**
- Compute the window: `start = lastSyncAt ?? (now - 30 days)`, `end = now`.
- Read workouts via the adapter, drop ones whose `sourceId` is already imported.
  Keep route-bearing (`hasRoute`) workouts as **selectable** candidates; keep
  no-route workouts too but flag them **non-importable** (v1 scope — surfaced as
  greyed-out in the UI), so the user sees the full picture.
- Returns the candidate list. **Writes nothing, uploads nothing, does not touch
  `lastSyncAt`.** This is the read step that populates the selection UI.
- Acceptance: test (fake adapter + fake import repo): already-imported workouts
  are excluded; route-bearing ones are returned as importable; no-route ones are
  returned but marked non-importable.

**Step I4 — `HealthSyncService.importWorkouts(Iterable<String> sourceIds)` — selective persist & enqueue.**
- Resolve the requested `sourceIds` against the most recent candidate read
  (re-read the window if needed). Ignore any id that is non-importable
  (no route) or already imported (idempotent — safe to call twice).
- For each selected workout: build GPX (`HealthWorkoutGpxBuilder`), persist via
  `LocalActivityRepository` as a `pending` `LocalActivityRecord` (set
  `activityType`, `startedAt`, `endedAt`, `distanceMeters`, derived
  `elapsedDurationSeconds`, `pointCount`; use the workout `sourceId` to derive the
  idempotency key/local id), then `markImported(sourceId, localActivityId)`, then
  trigger `ActivityUploadQueue` draining.
- Record `setLastSyncAt(now)` for display/auto-sync purposes only — dedup relies
  on the imported `sourceId` set, **not** the cursor, so unselected candidates
  remain importable on the next preview.
- Wrap per-workout failures as `AppException(healthImportFailed / healthGpxBuildFailed)`
  without aborting the whole batch; count successes. No coordinates in diagnostics.
- Acceptance: integration-style test with fakes: selecting 2 of N candidates ⇒
  exactly 2 pending records persisted and marked imported, queue drain invoked,
  the other candidates still appear on a subsequent `listImportable()`; a builder
  failure on one selected workout doesn't stop the others.

**Step I5 — `HealthSyncService.importAll()` — convenience for auto-sync / "select all".**
- Thin wrapper: `listImportable()` → take every importable candidate's `sourceId`
  → `importWorkouts(...)`. Used by the optional auto-sync-on-resume path
  (Phase N) and backing the UI's "select all + import" action.
- Acceptance: test: with M importable candidates, `importAll()` imports exactly M
  and skips non-importable ones.

---

### Phase J — Controller ✅

**Step J1 — `HealthSyncController` (`ChangeNotifier`).**
- File: `lib/features/health/controllers/health_sync_controller.dart`.
- Holds a `HealthSyncState`; exposes `loadStatus()`, `requestAccess()`,
  `loadImportableWorkouts()` (calls `listImportable`, fills
  `importableWorkouts`), selection mutators `toggleSelection(String sourceId)`,
  `selectAll()`, `clearSelection()` (each updates `selectedSourceIds` and
  notifies), `importSelected()` (calls `importWorkouts(selectedSourceIds)` then
  refreshes the candidate list and clears selection), and `importAll()`. Selection
  mutators must ignore non-importable (no-route) candidates. Follow
  `ActivityRecordingController`'s style: injected service + diagnostics, guarded
  `notifyListeners`, errors stored as `AppException?`.
- Acceptance: analyze clean; controller test driving state transitions
  (idle → loading → candidates listed → select subset → importing → done /
  error) with a fake service, including toggle/select-all/clear.

---

### Phase K — Composition root wiring ✅

**Step K1 — Platform adapter factory in `AppServices`.**
- File: `lib/core/services/app_services.dart`.
- Add `HealthPlatformAdapter createHealthPlatformAdapter()` that returns
  `HealthPackagePlatformAdapter` on `defaultTargetPlatform == android || iOS` and
  `UnsupportedHealthPlatformAdapter` otherwise — exactly mirroring
  `createActivityLocationRecorder()`.
- Acceptance: analyze clean.

**Step K2 — Wire repositories, service, and controller into `AppServices`.**
- Same file.
- Add lazy fields: `healthImportRepository`, `healthSyncSettings`,
  `healthSyncService` (passing `config.healthSyncEnabled`,
  `activityUploadQueue`, `localActivities`, `diagnostics`, etc.), and
  `healthSyncController`. Document lifetimes like the existing activity controller
  (owned by `AppServices`, consumers must not dispose).
- Acceptance: analyze clean; the existing
  `app_services_instance_guard_test.dart` still passes (no `AppServices.instance`
  use in new feature code); full suite still green.

---

### Phase L — Native platform configuration ✅

**Step L1 — Android: set `minSdk = 26` explicitly.**
- File: `android/app/build.gradle.kts`.
- The current `minSdk = flutter.minSdkVersion` resolves to **21** in Flutter
  3.38.4 — below the `health` package's requirement of **26**. Change to
  `minSdk = 26` (replaces the `flutter.minSdkVersion` reference).
- **User-facing impact:** drops Android 7.x and earlier (~1 % global share as of
  2026). Document this in the PR description and in §6 Risks below.
- Acceptance: `flutter build apk --debug` configures without a minSdk error.

**Step L1a — Android: migrate `MainActivity` to `FlutterFragmentActivity`.**
- File: `android/app/src/main/kotlin/com/endurain/endurain/MainActivity.kt`.
- The `health` package requires `FlutterFragmentActivity` (it calls
  `registerForActivityResult` inside the plugin, which needs a `FragmentActivity`
  host). Currently `MainActivity` extends `FlutterActivity`.
- Change: `import io.flutter.embedding.android.FlutterFragmentActivity` and
  `class MainActivity : FlutterFragmentActivity()`.
- **Regression risk:** the existing native background GPS recording channel
  (`NativeActivityRecorderChannel`) uses `MethodChannel` / `EventChannel` which
  are not affected by this switch. Verify end-to-end: start a recording, pause,
  resume, stop — confirm the channel still works.
- Acceptance: background GPS recording regression test passes; app builds clean.

**Step L2 — Android: declare Health Connect permissions & queries.**
- File: `android/app/src/main/AndroidManifest.xml`.
- Add the `android.permission.health.READ_*` permissions we use:
  `READ_EXERCISE`, `READ_HEART_RATE`, `READ_DISTANCE`,
  `READ_TOTAL_CALORIES_BURNED`, `READ_EXERCISE_ROUTE` (required for GPS routes,
  which is the v1 scope). Also add `android.permission.health.READ_HEALTH_DATA_HISTORY`
  if we want workouts older than 30 days.
- Add `ACCESS_FINE_LOCATION` permission — required alongside
  `READ_EXERCISE_ROUTE` (already declared for background GPS, but verify it
  remains present after any manifest refactor).
- Add a `<queries>` entry for the Health Connect package alongside the existing
  `PROCESS_TEXT` query:
  ```xml
  <package android:name="com.google.android.apps.healthdata" />
  ```
- Acceptance: app builds; permissions visible in the merged manifest.

**Step L3 — Android: add the permissions-rationale activities.**
- File: `android/app/src/main/AndroidManifest.xml`.
- The `health` package requires **two** intent-filter declarations per its README:
  1. On `.MainActivity` (or the main activity), add an `<intent-filter>` for
     `androidx.health.connect.action.SHOW_PERMISSIONS_RATIONALE` — required on
     Android 9–13 for the Health Connect rationale dialog.
  2. An `<activity-alias>` guarded by
     `android:permission="android.permission.START_VIEW_PERMISSION_USAGE"` with
     an `<intent-filter>` for `android.intent.action.VIEW_PERMISSION_USAGE` +
     category `android.intent.category.HEALTH_PERMISSIONS` — required on
     **Android 14+** for the system health permissions dialog.
- Acceptance: app builds; both Health Connect permission dialogs (≤13 and 14+
  paths) launch correctly.

**Step L4 — iOS: enable HealthKit capability & entitlement.**
- Files: `ios/Runner/Runner.entitlements`, Xcode project capability.
- Add the HealthKit entitlement (`com.apple.developer.healthkit`). Note in the doc
  that an Apple Developer account is required.
- Acceptance: `flutter build ios --no-codesign` (or Xcode) accepts the
  entitlement.

**Step L5 — iOS: add Info.plist usage description.**
- File: `ios/Runner/Info.plist`.
- Add `NSHealthShareUsageDescription` with a clear, user-facing reason. (No
  `NSHealthUpdateUsageDescription` in v1 — we only read.)
- Acceptance: build succeeds; the string is localizable/clear.

---

### Phase M — UI ✅

**Step M1 — Add localized strings for the health screen.**
- Files: `lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`; run `flutter gen-l10n`.
- Add a `Health` section: screen title, connect/authorize button, "refresh /
  find workouts", per-workout selection labels, "select all" / "clear", "import
  selected (n)", "import all", last-synced label, imported-count / result
  message, the "non-importable (no GPS route)" reason label, "install Health
  Connect" prompt, empty/unsupported messages, and the settings entry label.
  Each entry with a `description` (`"Used in: health_sync_screen.dart"`). Use a
  placeholder for the count in "import selected (n)".
- Acceptance: `flutter gen-l10n` succeeds; analyze clean.

**Step M2 — Build `HealthSyncScreen` with a selectable workout list.**
- File: `lib/features/health/screens/health_sync_screen.dart`.
- Use `AdaptiveScaffold` and adaptive widgets (match `settings_screen.dart`).
  Obtain the controller via `AppScope.servicesOf(context)`. Render:
  - SDK status + authorization state; a "Connect" action when not granted; the
    "Install Health Connect" call-to-action when
    `sdkStatus == needsProviderInstall`; an "unavailable" message on
    `unsupported`.
  - When granted: a **"Find workouts" / refresh** action that calls
    `loadImportableWorkouts()`, then a **list** of `importableWorkouts` showing
    type icon, date, distance, duration, and a route indicator. Each row has a
    checkbox bound to `selectedSourceIds` via `toggleSelection`; non-importable
    (no-route) rows are disabled/greyed with the reason label.
    - A **"select all" / "clear"** control and an **"Import selected (n)"**
      primary action (disabled when selection is empty), plus an **"Import
      all"** option.
    - Show a loading indicator while `isLoadingWorkouts` / `isImporting`,
      last-synced time, the imported-count result, and the route-consent
      guidance when `routeConsentDeniedCount > 0`.
  - All strings via `l10n`; Material icons.
- Acceptance: widget test using a fake controller: renders unsupported /
  needsInstall / granted-empty states; with candidates present, toggling rows
  updates the selection and the "Import selected (n)" label, non-importable rows
  are not selectable, and "Import selected" invokes `importSelected`. Analyze +
  format clean.

**Step M3 — Add the Settings entry point.**
- File: `lib/features/settings/settings_screen.dart`.
- Add an `AdaptiveListTile` that navigates to `HealthSyncScreen` using the
  project's `adaptivePush` helper (not raw `Navigator.push`) — mirror the
  pattern of the existing Server Settings and Activity History tiles. Gate the
  tile so it is hidden when `config.healthSyncEnabled` is false. Use
  `Icons.monitor_heart` and an `l10n` label.
- Acceptance: widget test: tile shown when flag on, hidden when off; tap
  navigates.

---

### Phase N — Optional auto-sync on resume (only if H1’s toggle is on) ✅

**Step N1 — Trigger sync on app-resume when enabled.**
- File: `lib/app.dart` (where the upload queue is already drained on resume).
- If `healthSyncEnabled` (config) **and** the user's `auto_sync_on_resume`
  setting is on **and** authorization is granted, call
  `healthSyncController.importAll()` on resume (best-effort, errors swallowed
  into state) — this imports every new candidate without prompting, for users who
  explicitly opted into auto-sync. Manual users keep the review-and-select flow.
  Keep it behind the same guards so the default behavior is unchanged.
- Acceptance: test/verification that resume with the toggle off does nothing;
  with it on (and a fake service) triggers one `importAll`.

---

### Phase O — Hardening, tests, and gates ✅

**Step O1 — Coverage & full-suite pass.**
- Run `flutter test --coverage` then `dart run tool/check_coverage.dart`. Add
  tests for any file below the gate (the repo keeps ~90%).
- Acceptance: full suite green; coverage gate green; `flutter analyze` clean;
  `dart format .` clean.

**Step O2 — Architecture-guard & docs review.**
- Run `test/architecture/app_services_instance_guard_test.dart`. Update this
  devdoc's status to "implemented" and note any deviations (e.g. final `health`
  package version, the actual `minSdk`, any deferred indoor-workout handling).
- Acceptance: guard test passes; doc reflects reality.

---

## 6. Risks & decisions to confirm before starting

- **Backend GPX-only ingest** — v1 imports route-bearing workouts only. If the
  Endurain server later exposes a structured (non-GPX) activity ingest, indoor
  workouts can be added without changing the source/abstraction design.
- **`health` package transitive deps** — confirm at Step E1 that nothing pulls
  Google Play Services / Firebase. The library itself is clean (MIT, pure
  AndroidX); the risk is future version bumps pulling in new deps.
- **Third-party route consent on Android** — reading routes recorded by *other*
  apps (Samsung Health, Garmin — the primary v1 use case) returns
  `ConsentRequired` because the plugin does not expose
  `ExerciseRouteRequestContract`. The only user-facing remedy is granting "Always
  allow" for exercise routes inside the Health Connect app. Steps E4 and M2 must
  design for this explicitly (graceful skip + clear UI guidance). Do not assume
  routes are readable at install-time.
- **`FlutterFragmentActivity` migration** (Step L1a) — required by the `health`
  plugin but touches the same `MainActivity` that hosts the background GPS
  recording channel. Regression-test recording before marking L1a done.
- **minSdk raised to 26** — drops Android 7.x. Negligible global share in 2026,
  but confirm with the project maintainer before merging.
- **F-Droid on Android < 14** — the Health Connect runtime APK is proprietary
  and Play-Store-only on Android 9–13. De-Googled users on those versions will
  see `HealthSdkStatus.unsupported`. This is handled by the existing degradation
  path and is not a blocker, but should be documented in the app's release notes.
- **iOS entitlement** — requires an Apple Developer account and App Store review
  justification for health data access.
- **Permission model differences** — HealthKit and Health Connect have different
  permission UX; the `HealthAuthorizationStatus` abstraction normalizes them, but
  the screen copy (Step M1) should read naturally on both.
```
