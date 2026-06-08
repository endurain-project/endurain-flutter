# Completed Activity Local Retention Plan

## Goal

Keep completed activity recordings (metadata + GPX) on-device after upload,
letting users browse their history offline and re-upload if needed.

## Current behaviour

After recording stops and the upload attempt completes:

1. Activity metadata is written to `<support-dir>/activities/index.json`
   (schema v1 JSON manifest) with `uploadStatus` set to `uploaded`,
   `pending`, or `failed`.
2. The GPX file is retained at `<support-dir>/activities/gpx/<id>.gpx`
   unless the user explicitly deletes the activity.
3. `ActivityRetentionSettingsRepository` (key `activity_retain_uploaded_gpx`)
   controls whether uploaded GPX files are kept. Default is `true`.

## Planned metadata store migration (SQLite)

The JSON manifest approach rewrites the entire file on every upsert/delete.
The target store is `SqfliteActivityStore` which is already implemented
behind the `LocalActivityStore` interface.

### Migration steps (not yet wired)

1. On app first-launch after the SQLite dependency lands, construct
   `SqfliteActivityStore` with a `manifestReader` pointing at the existing
   `JsonManifestActivityStore`.
2. `SqfliteActivityStore.onCreate` imports all valid manifest records into
   the `local_activity` table (malformed entries are skipped).
3. After successful open, the caller deletes `index.json` to prevent
   double-read on next launch.
4. If the SQLite open fails, `LocalActivityRepository` falls back to
   `JsonManifestActivityStore`; no data loss occurs.

### Wiring checklist

- [ ] `AppServices.localActivityStore` — choose SQLite or JSON based on
  availability/migration state.
- [ ] Pass `manifestReader: () => jsonStore.list()` to `SqfliteActivityStore`.
- [ ] Delete `index.json` after first successful SQLite open.
- [ ] Update `LocalActivityRepository` to accept `LocalActivityStore` from DI
  (already accepts it via constructor).

## GPX retention policy

| Setting                        | Behaviour                                  |
|--------------------------------|--------------------------------------------|
| `retainUploadedGpx = true`     | GPX kept on device after upload (default)  |
| `retainUploadedGpx = false`    | GPX deleted after successful upload         |

The setting is stored in `flutter_secure_storage` under
`activity_retain_uploaded_gpx`. Users can toggle it in Settings.
