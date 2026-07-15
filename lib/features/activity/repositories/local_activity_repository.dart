import 'dart:io';

import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_store.dart';
import 'package:endurain/features/activity/repositories/sqflite_activity_store.dart';
import 'package:endurain/features/activity/services/local_activity_gpx_storage.dart';

/// Facade that combines metadata storage (delegated to [LocalActivityStore])
/// with GPX file I/O owned by [LocalActivityGpxStorage].
class LocalActivityRepository {
  LocalActivityRepository({
    Future<Directory> Function()? supportDirectoryProvider,
    LocalActivityGpxStorage? gpxStorage,
    LocalActivityStore? store,
  }) : _gpxStorage =
           gpxStorage ??
           LocalActivityGpxStorage(
             supportDirectoryProvider: supportDirectoryProvider,
           ),
       _store = store ?? SqfliteActivityStore();

  final LocalActivityGpxStorage _gpxStorage;
  final LocalActivityStore _store;

  Future<List<LocalActivityRecord>> list() => _store.list();

  Future<LocalActivityRecord?> get(String id) => _store.get(id);

  Future<List<LocalActivityRecord>> getByIds(Set<String> ids) =>
      _store.getByIds(ids);

  Future<String> writeGpx({required String id, required String gpx}) =>
      _gpxStorage.write(id: id, gpx: gpx);

  Future<String> readGpxFilePath(LocalActivityRecord record) =>
      _gpxStorage.readFilePath(record.gpxFileName);

  Future<String> readGpxContents(LocalActivityRecord record) =>
      _gpxStorage.read(record.gpxFileName);

  Future<bool> hasGpx(LocalActivityRecord record) =>
      _gpxStorage.exists(record.gpxFileName);

  Future<void> deleteGpx(LocalActivityRecord record) =>
      _gpxStorage.delete(record.gpxFileName);

  Future<void> upsert(LocalActivityRecord record) => _store.upsert(record);

  Future<bool> updateIfPresent(LocalActivityRecord record) =>
      _store.updateIfPresent(record);

  Future<List<LocalActivityRecord>> listPage({
    required int offset,
    required int limit,
  }) => _store.listPage(offset: offset, limit: limit);

  Future<List<LocalActivityRecord>> listByUploadStatus(
    Set<LocalActivityUploadStatus> statuses,
  ) => _store.listByUploadStatus(statuses);

  Future<int> count() => _store.count();

  Future<int> bindUnassignedToProfile({
    required String origin,
    required String profileId,
    required DateTime updatedAt,
  }) => _store.bindUnassignedToProfile(
    origin: origin,
    profileId: profileId,
    updatedAt: updatedAt,
  );

  Future<void> delete(String id) async {
    final record = await _store.get(id);
    if (record == null) {
      return;
    }
    await _gpxStorage.delete(record.gpxFileName);
    await _store.delete(id);
  }
}
