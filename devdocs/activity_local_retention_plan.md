# Completed Activity Local Retention Plan

## Goal

Keep completed activity recordings (metadata + GPX) on-device after upload,
letting users browse their history offline and re-upload if needed.

## Current behaviour

After recording stops and the upload attempt completes:

1. Activity metadata is written to `<support-dir>/activity.db` (SQLite, schema
   v1) with `uploadStatus` set to `uploaded`, `pending`, or `failed`.
   On first open after the migration, any records from the legacy
   `activities/index.json` JSON manifest are imported automatically.
2. The GPX file is retained at `<support-dir>/activities/gpx/<id>.gpx`
   unless the user explicitly deletes the activity.
3. `ActivityRetentionSettingsRepository` (key `activity_retain_uploaded_gpx`)
   controls whether uploaded GPX files are kept. Default is `true`.

## SQLite metadata store (implemented)

`SqfliteActivityStore` is wired as the default backend in `AppServices`. On
first open it migrates any existing JSON manifest records via the
`manifestReader` callback. Both `SqfliteActivityStore` and
`JsonManifestActivityStore` implement the full `LocalActivityStore` interface
including `listPage(offset, limit)` and `count()` for paginated history loading.

### Wiring checklist

- [x] `AppServices.localActivities` — constructs `SqfliteActivityStore` with
  `manifestReader: () => JsonManifestActivityStore(diagnostics: diagnostics).list()`.
- [x] `LocalActivityRepository` accepts `LocalActivityStore` from DI.
- [x] `listPage` / `count` added to the interface and both store implementations.
- [x] History controller uses `listPage(offset: 0, limit: 20)` for initial load
  and `loadMore()` to append subsequent pages.
- [ ] Delete `index.json` after first successful SQLite open (nice-to-have;
  legacy file is harmless and the manifest reader is idempotent).

## GPX retention policy

| Setting                        | Behaviour                                  |
|--------------------------------|--------------------------------------------|
| `retainUploadedGpx = true`     | GPX kept on device after upload (default)  |
| `retainUploadedGpx = false`    | GPX deleted after successful upload         |

The setting is stored in `flutter_secure_storage` under
`activity_retain_uploaded_gpx`. Users can toggle it in Settings.
