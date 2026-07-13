import 'package:endurain/features/activity/models/local_activity_record.dart';

/// Abstraction over the activity-metadata backing store.
abstract interface class LocalActivityStore {
  Future<List<LocalActivityRecord>> list();
  Future<LocalActivityRecord?> get(String id);
  Future<List<LocalActivityRecord>> getByIds(Set<String> ids);
  Future<void> upsert(LocalActivityRecord record);
  Future<void> delete(String id);

  /// Returns at most [limit] records ordered newest-first, skipping the
  /// first [offset] records. Used for incremental history loading.
  Future<List<LocalActivityRecord>> listPage({
    required int offset,
    required int limit,
  });

  /// Returns every record whose [LocalActivityRecord.uploadStatus] is in
  /// [statuses], ordered oldest-first so the durable upload queue retries
  /// activities in the order they were recorded.
  Future<List<LocalActivityRecord>> listByUploadStatus(
    Set<LocalActivityUploadStatus> statuses,
  );

  /// Returns the total number of stored records.
  Future<int> count();
}
