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
  native recorder is unavailable (macOS, test environments).
- **Controller** (`ActivityRecordingController`): owns the recording lifecycle,
  drives upload on stop, persists activity metadata to local storage.
- **GPX generation**: track points serialized to GPX 1.1 on recording
  completion.
- **Local storage** (`LocalActivityRepository` → `SqfliteActivityStore`):
  SQLite-backed store at `<support-dir>/activity.db` (schema v1). On first
  open, existing JSON manifest records are migrated automatically via the
  `manifestReader` callback injected by `AppServices`.
- **Pagination API** (`listPage(offset, limit)` / `count()`): both
  `SqfliteActivityStore` (SQL-level limit/offset) and
  `JsonManifestActivityStore` (in-memory fallback) implement the interface.
  `LocalActivityRepository` exposes the same API. The history controller
  loads 20 records per page with a "Load more" button in the UI.
- **Upload service** (`ActivityUploadService`): multipart GPX upload with
  bounded transient retry (3 attempts, 2-second back-off).
- **History UI** (`LocalActivityHistoryController`, `ActivityHistoryScreen`,
  `ActivityDetailsScreen`): list, detail, retry, and delete. History screen
  calls `retryFailedUploads()` when the app resumes.
- **Resume-triggered retry** (`retryFailedUploads()`): on
  `AppLifecycleState.resumed`, `ActivityHistoryScreen` retries all records
  with `uploadStatus == failed` in a best-effort loop.

## Remaining work

- **Connectivity-triggered retry**: re-attempt failed uploads when the app
  foregrounds with a network connection (durable queue, not yet implemented).
- **Server-synced history**: pull server activities and merge with local
  records once server API is ready.
