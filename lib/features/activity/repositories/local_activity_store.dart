import 'package:endurain/features/activity/models/local_activity_record.dart';

/// Abstraction over the activity-metadata backing store.
abstract interface class LocalActivityStore {
  Future<List<LocalActivityRecord>> list();
  Future<LocalActivityRecord?> get(String id);
  Future<void> upsert(LocalActivityRecord record);
  Future<void> delete(String id);
}
