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

  Future<bool> isImported({required String origin, required String sourceId}) =>
      _run(() => _store.isImported(origin: origin, sourceId: sourceId));

  Future<String?> localActivityIdFor({
    required String origin,
    required String sourceId,
  }) =>
      _run(() => _store.localActivityIdFor(origin: origin, sourceId: sourceId));

  Future<String?> legacyLocalActivityIdFor(String sourceId) =>
      _run(() => _store.legacyLocalActivityIdFor(sourceId));

  Future<void> adoptLegacyImport({
    required String origin,
    required String sourceId,
  }) =>
      _run(() => _store.adoptLegacyImport(origin: origin, sourceId: sourceId));

  Future<void> markImported({
    required String origin,
    required String sourceId,
    required String localActivityId,
  }) => _run(
    () => _store.markImported(
      origin: origin,
      sourceId: sourceId,
      localActivityId: localActivityId,
    ),
  );

  Future<void> removeByLocalActivityId(String localActivityId) =>
      _run(() => _store.removeByLocalActivityId(localActivityId));

  Future<void> clearOrigin(String origin) =>
      _run(() => _store.clearOrigin(origin));

  Future<List<HealthImportedWorkout>> listImported({
    required String origin,
    required int offset,
    required int limit,
  }) => _run(
    () => _store.listImported(origin: origin, offset: offset, limit: limit),
  );

  Future<DateTime?> lastSyncAt(String origin) =>
      _run(() => _store.lastSyncAt(origin));

  Future<void> setLastSyncAt(String origin, DateTime at) =>
      _run(() => _store.setLastSyncAt(origin, at));

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
