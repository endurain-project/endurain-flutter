# Completed Activity Local Retention Plan

## Goal

Keep completed activity recordings (metadata + GPX) on-device after upload,
letting users browse their history offline and re-upload if needed.

## Current behaviour

After recording stops and the upload attempt completes:

1. Activity metadata is written to `activity.db` (SQLite, schema v1) under the
   platform databases directory, with `uploadStatus` set to `uploaded`,
   `pending`, or `failed`.
2. The GPX file is retained at `<app-support>/activity_records/gpx/<id>.gpx`
   unless the user explicitly deletes the activity.
3. `ActivityRetentionSettingsRepository` (key `activity_retain_uploaded_gpx`)
   controls whether uploaded GPX files are kept. Default is `true`.

## SQLite metadata store (implemented)

`SqfliteActivityStore` is the single metadata backend, wired as the default in
`AppServices`. It implements the full `LocalActivityStore` interface including
`listPage(offset, limit)` and `count()` for paginated history loading.

### Wiring checklist

- [x] `AppServices.localActivities` — constructs `SqfliteActivityStore`.
- [x] `LocalActivityRepository` accepts `LocalActivityStore` from DI.
- [x] `listPage` / `count` on the interface and the store implementation.
- [x] History controller uses `listPage(offset: 0, limit: 20)` for initial load
  and `loadMore()` to append subsequent pages.

## GPX retention policy

| Setting                        | Behaviour                                  |
|--------------------------------|--------------------------------------------|
| `retainUploadedGpx = true`     | GPX kept on device after upload (default)  |
| `retainUploadedGpx = false`    | GPX deleted after successful upload         |

The setting is stored in `flutter_secure_storage` under
`activity_retain_uploaded_gpx`. Users can toggle it in Settings.
