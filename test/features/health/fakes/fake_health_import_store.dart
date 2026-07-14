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
    required String profileId,
    required String sourceId,
  }) async => _imported.contains('$profileId::$sourceId');

  @override
  Future<String?> localActivityIdFor({
    required String profileId,
    required String sourceId,
  }) async => _localIds['$profileId::$sourceId'];

  @override
  Future<String?> legacyLocalActivityIdFor(String sourceId) async =>
      _localIds['legacy://unassigned::$sourceId'];

  @override
  Future<void> adoptLegacyImport({
    required String profileId,
    required String sourceId,
  }) async {
    final legacyKey = 'legacy://unassigned::$sourceId';
    final localId = _localIds.remove(legacyKey);
    _imported.remove(legacyKey);
    if (localId != null) {
      _localIds['$profileId::$sourceId'] = localId;
      _imported.add('$profileId::$sourceId');
    }
  }

  @override
  Future<void> markImported({
    required String profileId,
    required String sourceId,
    required String localActivityId,
  }) async {
    _imported.add('$profileId::$sourceId');
    _localIds['$profileId::$sourceId'] = localActivityId;
    _importedAt['$profileId::$sourceId'] = DateTime.now().toUtc();
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
  Future<void> clearForProfile(String profileId) async {
    _imported.removeWhere((value) => value.startsWith('$profileId::'));
    _localIds.removeWhere((key, _) => key.startsWith('$profileId::'));
    _importedAt.removeWhere((key, _) => key.startsWith('$profileId::'));
    _lastSyncAt = null;
  }

  @override
  Future<DateTime?> lastSyncAt(String profileId) async => _lastSyncAt;

  @override
  Future<void> setLastSyncAt(String profileId, DateTime at) async =>
      _lastSyncAt = at;

  @override
  Future<List<HealthImportedWorkout>> listImported({
    required String profileId,
    required int offset,
    required int limit,
  }) async {
    final prefix = '$profileId::';
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
