# Activity Tracking MVP Plan

## Goal

Enable users to record, store, and upload GPS-based activities entirely
on-device, with graceful failure handling and optional server sync.

## Implemented

- **Native Android recorder** (`ActivityRecorderService.kt`): foreground
  service with GPS/network provider selection, pause/resume, point
  persistence, and failure emission. Provider-loss during recording
  persists failed state and stops the service.
- **Native iOS recorder** (`CoreLocationActivityRecorder.swift`): mirrors
  Android behaviour using `CLLocationManager` authorization callbacks.
- **Geolocator fallback** (`GeolocatorActivityLocationRecorder`): used when
  native recorder is unavailable (test/host environments).
- **Controller** (`ActivityRecordingController`): owns the recording lifecycle,
  drives upload on stop, persists activity metadata to local storage.
- **GPX generation**: track points serialized to GPX 1.1 on recording
  completion.
- **Local storage** (`LocalActivityRepository` → `SqfliteActivityStore`):
  SQLite-backed store at `activity.db` (schema v1) under the platform
  databases directory. `SqfliteActivityStore` is the single metadata backend.
- **Pagination API** (`listPage(offset, limit)` / `count()`): the
  `SqfliteActivityStore` implements SQL-level limit/offset paging.
  `LocalActivityRepository` exposes the same API. The history controller
  loads 20 records per page with a "Load more" button in the UI.
- **Upload service** (`ActivityUploadService`): multipart GPX upload with
  bounded transient retry (3 attempts, 2-second back-off).
- **History UI** (`LocalActivityHistoryController`, `ActivityHistoryScreen`,
  `ActivityDetailsScreen`): list, detail, retry, and delete.
- **App-lifetime upload queue** (`ActivityUploadQueue`): durable, single-flight
  queue owned by `AppServices`. It scans local records whose `uploadStatus` is
  `pending` or `failed` and drains them via `ActivityUploadService`. A finished
  activity is always persisted locally first (GPX + metadata), so an activity
  recorded with no connectivity is uploaded later without the user having to
  open the history screen and tap retry.
- **Resume-triggered drain**: on `AppLifecycleState.resumed`, the root `App`
  (`lib/app.dart`) calls `activityUploadQueue.drain()`. `ActivityHistoryScreen`
  also drains the queue on resume while it is visible. Concurrent calls share
  the same in-progress run, so resume and screen-visibility cannot start two
  overlapping drains.
- **Connectivity-triggered drain**: `ActivityUploadQueue` listens to a
  `connectivitySignal` stream and drains when it emits `true`. `AppServices`
  wires this to `ConnectivityService` (a thin `connectivity_plus` wrapper), so
  failed uploads retry the moment connectivity is restored while the app is
  foregrounded — not only on app-resume. Platform errors from the connectivity
  plugin are swallowed, degrading to resume-only draining rather than crashing.

## Remaining work

- **Server-synced history**: pull server activities and merge with local
  records once server API is ready.
