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
- **Local storage** (`LocalActivityRepository` → `JsonManifestActivityStore`):
  JSON manifest at `<support-dir>/activities/index.json` (schema v1).
- **Upload service** (`ActivityUploadService`): multipart GPX upload with
  bounded transient retry (3 attempts, 2-second back-off).
- **History UI** (`LocalActivityHistoryController`, `ActivityHistoryScreen`,
  `ActivityDetailsScreen`): list, detail, retry, and delete.

## Remaining work

- **Wire `SqfliteActivityStore`** as the default backend in `AppServices` (the
  abstraction exists; the switch just needs wiring and a migration reader passed
  from `LocalActivityRepository`).
- **Pagination**: add `listPage(offset, limit)` to `LocalActivityStore` and
  update the history controller.
- **Connectivity-triggered retry**: re-attempt failed uploads when the app
  foregrounds with a network connection.
- **Server-synced history**: pull server activities and merge with local
  records once server API is ready.
