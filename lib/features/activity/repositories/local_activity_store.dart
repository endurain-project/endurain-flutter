import 'package:endurain/features/activity/models/local_activity_record.dart';

/// Abstraction over the activity-metadata backing store.
///
/// Concrete implementations include [JsonManifestActivityStore] (current) and
/// a future SQLite-backed store.  The interface intentionally covers only
/// metadata operations; GPX file I/O remains owned by
/// [LocalActivityRepository].
abstract interface class LocalActivityStore {
  Future<List<LocalActivityRecord>> list();
  Future<LocalActivityRecord?> get(String id);
  Future<void> upsert(LocalActivityRecord record);
  Future<void> delete(String id);
}
