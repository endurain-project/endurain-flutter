import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/repositories/health_import_store.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/repositories/sqflite_health_import_store.dart';

/// Facade over [HealthImportStore] that services depend on.
///
/// Constructed with a concrete [HealthImportStore] (defaults to
/// [SqfliteHealthImportStore]). Mirrors the pattern used by
/// `LocalActivityRepository` over its store.
class HealthImportRepository {
  HealthImportRepository({HealthImportStore? store})
    : _store = store ?? SqfliteHealthImportStore();

  final HealthImportStore _store;

  Future<bool> isImported({
    required String profileId,
    required String sourceId,
  }) => _run(() => _store.isImported(profileId: profileId, sourceId: sourceId));

  Future<String?> localActivityIdFor({
    required String profileId,
    required String sourceId,
  }) => _run(
    () => _store.localActivityIdFor(profileId: profileId, sourceId: sourceId),
  );

  Future<List<({String profileId, String localActivityId})>> importsForSource(
    String sourceId,
  ) => _run(() => _store.importsForSource(sourceId));

  Future<void> reassignImportProfile({
    required String sourceId,
    required String fromProfileId,
    required String toProfileId,
  }) => _run(
    () => _store.reassignImportProfile(
      sourceId: sourceId,
      fromProfileId: fromProfileId,
      toProfileId: toProfileId,
    ),
  );

  Future<void> markImported({
    required String profileId,
    required String sourceId,
    required String localActivityId,
  }) => _run(
    () => _store.markImported(
      profileId: profileId,
      sourceId: sourceId,
      localActivityId: localActivityId,
    ),
  );

  Future<void> removeByLocalActivityId(String localActivityId) =>
      _run(() => _store.removeByLocalActivityId(localActivityId));

  Future<void> clearForProfile(String profileId) =>
      _run(() => _store.clearForProfile(profileId));

  Future<List<HealthImportedWorkout>> listImported({
    required String profileId,
    required int offset,
    required int limit,
  }) => _run(
    () =>
        _store.listImported(profileId: profileId, offset: offset, limit: limit),
  );

  Future<DateTime?> lastSyncAt(String profileId) =>
      _run(() => _store.lastSyncAt(profileId));

  Future<void> setLastSyncAt(String profileId, DateTime at) =>
      _run(() => _store.setLastSyncAt(profileId, at));

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.healthImportFailed, cause: error);
    }
  }
}
