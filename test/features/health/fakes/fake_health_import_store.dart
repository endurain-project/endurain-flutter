import 'package:endurain/features/health/repositories/health_import_store.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';

/// In-memory [HealthImportStore] for tests.
class FakeHealthImportStore implements HealthImportStore {
  final Set<String> _imported = {};
  final Map<String, String> _localIds = {};
  final Map<String, DateTime> _importedAt = {};
  DateTime? _lastSyncAt;

  @override
  Future<bool> isImported({
    required String origin,
    required String sourceId,
  }) async => _imported.contains('$origin::$sourceId');

  @override
  Future<String?> localActivityIdFor({
    required String origin,
    required String sourceId,
  }) async => _localIds['$origin::$sourceId'];

  @override
  Future<String?> legacyLocalActivityIdFor(String sourceId) async =>
      _localIds['legacy://unassigned::$sourceId'];

  @override
  Future<void> adoptLegacyImport({
    required String origin,
    required String sourceId,
  }) async {
    final legacyKey = 'legacy://unassigned::$sourceId';
    final localId = _localIds.remove(legacyKey);
    _imported.remove(legacyKey);
    if (localId != null) {
      _localIds['$origin::$sourceId'] = localId;
      _imported.add('$origin::$sourceId');
    }
  }

  @override
  Future<void> markImported({
    required String origin,
    required String sourceId,
    required String localActivityId,
  }) async {
    _imported.add('$origin::$sourceId');
    _localIds['$origin::$sourceId'] = localActivityId;
    _importedAt['$origin::$sourceId'] = DateTime.now().toUtc();
  }

  @override
  Future<void> removeByLocalActivityId(String localActivityId) async {
    final keys = _localIds.entries
        .where((entry) => entry.value == localActivityId)
        .map((entry) => entry.key)
        .toList();
    for (final key in keys) {
      _localIds.remove(key);
      _importedAt.remove(key);
      _imported.remove(key);
    }
  }

  @override
  Future<void> clearOrigin(String origin) async {
    _imported.removeWhere((value) => value.startsWith('$origin::'));
    _localIds.removeWhere((key, _) => key.startsWith('$origin::'));
    _importedAt.removeWhere((key, _) => key.startsWith('$origin::'));
    _lastSyncAt = null;
  }

  @override
  Future<DateTime?> lastSyncAt(String origin) async => _lastSyncAt;

  @override
  Future<void> setLastSyncAt(String origin, DateTime at) async =>
      _lastSyncAt = at;

  @override
  Future<List<HealthImportedWorkout>> listImported({
    required String origin,
    required int offset,
    required int limit,
  }) async {
    final prefix = '$origin::';
    final entries =
        _localIds.entries
            .where((entry) => entry.key.startsWith(prefix))
            .map(
              (entry) => HealthImportedWorkout(
                sourceId: entry.key.substring(prefix.length),
                localActivityId: entry.value,
                importedAt: _importedAt[entry.key]!,
              ),
            )
            .toList()
          ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return entries.skip(offset).take(limit).toList();
  }
}
