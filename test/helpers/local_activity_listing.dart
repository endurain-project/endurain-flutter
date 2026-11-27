import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_store.dart';

const int _everything = 1 << 30;

/// Test-only listing helpers; production code pages through `listPage` or uses
/// the upload-queue query, so the store interfaces expose no unbounded list.
extension LocalActivityStoreListing on LocalActivityStore {
  /// Every record, newest-first.
  Future<List<LocalActivityRecord>> list() =>
      listPage(offset: 0, limit: _everything);

  /// Every record whose upload status is in [statuses], oldest-first.
  Future<List<LocalActivityRecord>> listByUploadStatus(
    Set<LocalActivityUploadStatus> statuses,
  ) async {
    final records = await list();
    return records.where((r) => statuses.contains(r.uploadStatus)).toList()
      ..sort((a, b) => a.endedAt.compareTo(b.endedAt));
  }
}

extension LocalActivityRepositoryListing on LocalActivityRepository {
  /// Every record, newest-first.
  Future<List<LocalActivityRecord>> list() =>
      listPage(offset: 0, limit: _everything);

  /// Every record whose upload status is in [statuses], oldest-first.
  Future<List<LocalActivityRecord>> listByUploadStatus(
    Set<LocalActivityUploadStatus> statuses,
  ) async {
    final records = await list();
    return records.where((r) => statuses.contains(r.uploadStatus)).toList()
      ..sort((a, b) => a.endedAt.compareTo(b.endedAt));
  }
}
