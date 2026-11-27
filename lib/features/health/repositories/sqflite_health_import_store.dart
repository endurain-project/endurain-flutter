import 'package:endurain/core/utils/sqlite_database_handle.dart';
import 'package:endurain/core/utils/sqlite_migration_runner.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/repositories/health_import_store.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed [HealthImportStore] implemented with sqflite.
///
/// The `profile_id` columns store the connection profile id (the name the
/// [HealthImportStore] API uses). Schema v2 originally named these columns
/// `origin`; the v3 migration rebuilds the tables to rename them. A rebuild is
/// used rather than `ALTER TABLE ... RENAME COLUMN`, which needs SQLite 3.25+
/// (unavailable on Android API 26–28).
///
/// Inject a custom `databaseFactory` and `databasePath` in tests:
/// ```dart
/// SqfliteHealthImportStore(
///   databaseFactory: databaseFactoryFfi,
///   databasePath: inMemoryDatabasePath,
/// )
/// ```
class SqfliteHealthImportStore implements HealthImportStore {
  SqfliteHealthImportStore({
    DatabaseFactory? databaseFactory,
    String? databasePath,
    DateTime Function()? now,
  }) : _databaseFactory = databaseFactory,
       _databasePath = databasePath,
       _now = now ?? DateTime.now;

  static const int _schemaVersion = 3;
  static const String _dbFileName = 'health_import.db';
  static const String _tableVersion = 'schema_version';
  static const String _tableImported = 'imported_workouts';
  static const String _tableSync = 'sync_state';
  static const String _legacyProfileId = 'legacy://unassigned';

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;
  final DateTime Function() _now;

  late final SqliteMigrationRunner _migrationRunner = SqliteMigrationRunner(
    migrations: {1: _migrateToV1, 2: _migrateToV2, 3: _migrateToV3},
    recordVersion: _recordSchemaVersion,
  );

  late final SqliteDatabaseHandle _database = SqliteDatabaseHandle(
    fileName: _dbFileName,
    schemaVersion: _schemaVersion,
    migrationRunner: _migrationRunner,
    databaseFactory: _databaseFactory,
    databasePath: _databasePath,
  );

  Future<Database> _open() => _database.open();

  /// Closes the underlying database; a later call reopens it.
  @visibleForTesting
  Future<void> close() => _database.close();

  Future<void> _recordSchemaVersion(Database db, int version) async {
    await db.execute(
      'INSERT OR REPLACE INTO $_tableVersion (id, version) VALUES (1, ?)',
      [version],
    );
  }

  Future<void> _migrateToV1(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableVersion (
        id      INTEGER PRIMARY KEY,
        version INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tableImported (
        source_id           TEXT PRIMARY KEY,
        local_activity_id   TEXT NOT NULL,
        imported_at         TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE key_value (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateToV2(Database db) async {
    await db.execute(
      'ALTER TABLE $_tableImported RENAME TO imported_workouts_v1',
    );
    await db.execute('''
      CREATE TABLE $_tableImported (
        origin              TEXT NOT NULL,
        source_id           TEXT NOT NULL,
        local_activity_id   TEXT NOT NULL,
        imported_at         TEXT NOT NULL,
        PRIMARY KEY (origin, source_id)
      )
    ''');
    await db.execute(
      '''
      INSERT INTO $_tableImported (
        origin, source_id, local_activity_id, imported_at
      )
      SELECT ?, source_id, local_activity_id, imported_at
      FROM imported_workouts_v1
    ''',
      [_legacyProfileId],
    );
    await db.execute('DROP TABLE imported_workouts_v1');
    await db.execute('''
      CREATE TABLE $_tableSync (
        origin        TEXT PRIMARY KEY,
        last_sync_at  TEXT NOT NULL
      )
    ''');
    final legacySync = await db.query(
      'key_value',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['last_sync_at'],
      limit: 1,
    );
    if (legacySync.isNotEmpty) {
      await db.insert(_tableSync, {
        'origin': _legacyProfileId,
        'last_sync_at': legacySync.first['value'],
      });
    }
    await db.execute('DROP TABLE key_value');
    await db.execute(
      'CREATE INDEX imported_workouts_local_id_idx '
      'ON $_tableImported (local_activity_id)',
    );
  }

  /// Renames the `origin` columns — which have always held the connection
  /// profile id — to `profile_id` in both tables, removing the historical
  /// naming mismatch. Rebuilds the tables (rather than `RENAME COLUMN`) so the
  /// migration runs on the SQLite shipped with Android API 26+.
  Future<void> _migrateToV3(Database db) async {
    await db.execute(
      'ALTER TABLE $_tableImported RENAME TO imported_workouts_v2',
    );
    await db.execute('''
      CREATE TABLE $_tableImported (
        profile_id          TEXT NOT NULL,
        source_id           TEXT NOT NULL,
        local_activity_id   TEXT NOT NULL,
        imported_at         TEXT NOT NULL,
        PRIMARY KEY (profile_id, source_id)
      )
    ''');
    await db.execute('''
      INSERT INTO $_tableImported (
        profile_id, source_id, local_activity_id, imported_at
      )
      SELECT origin, source_id, local_activity_id, imported_at
      FROM imported_workouts_v2
    ''');
    await db.execute('DROP TABLE imported_workouts_v2');
    await db.execute(
      'CREATE INDEX imported_workouts_local_id_idx '
      'ON $_tableImported (local_activity_id)',
    );

    await db.execute('ALTER TABLE $_tableSync RENAME TO sync_state_v2');
    await db.execute('''
      CREATE TABLE $_tableSync (
        profile_id    TEXT PRIMARY KEY,
        last_sync_at  TEXT NOT NULL
      )
    ''');
    await db.execute('''
      INSERT INTO $_tableSync (profile_id, last_sync_at)
      SELECT origin, last_sync_at FROM sync_state_v2
    ''');
    await db.execute('DROP TABLE sync_state_v2');
  }

  // ── HealthImportStore ───────────────────────────────────────────────────

  @override
  Future<bool> isImported({
    required String profileId,
    required String sourceId,
  }) async {
    return await localActivityIdFor(profileId: profileId, sourceId: sourceId) !=
        null;
  }

  @override
  Future<String?> localActivityIdFor({
    required String profileId,
    required String sourceId,
  }) async {
    final db = await _open();
    final rows = await db.query(
      _tableImported,
      columns: ['local_activity_id'],
      where: 'profile_id = ? AND source_id = ?',
      whereArgs: [profileId, sourceId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return rows.first['local_activity_id'] as String?;
    }
    return null;
  }

  @override
  Future<List<({String profileId, String localActivityId})>> importsForSource(
    String sourceId,
  ) async {
    final db = await _open();
    final rows = await db.query(
      _tableImported,
      columns: ['profile_id', 'local_activity_id'],
      where: 'source_id = ?',
      whereArgs: [sourceId],
    );
    return [
      for (final row in rows)
        (
          profileId: row['profile_id'] as String,
          localActivityId: row['local_activity_id'] as String,
        ),
    ];
  }

  @override
  Future<void> reassignImportProfile({
    required String sourceId,
    required String fromProfileId,
    required String toProfileId,
  }) async {
    if (fromProfileId == toProfileId) {
      return;
    }
    final db = await _open();
    await db.transaction((txn) async {
      // Clear any stale target row so re-keying can never hit the
      // (profile_id, source_id) primary key constraint.
      await txn.delete(
        _tableImported,
        where: 'profile_id = ? AND source_id = ?',
        whereArgs: [toProfileId, sourceId],
      );
      await txn.update(
        _tableImported,
        {'profile_id': toProfileId},
        where: 'profile_id = ? AND source_id = ?',
        whereArgs: [fromProfileId, sourceId],
      );
    });
  }

  @override
  Future<List<String>> listProfileIds() async {
    final db = await _open();
    final rows = await db.rawQuery(
      'SELECT profile_id FROM $_tableImported '
      'UNION SELECT profile_id FROM $_tableSync',
    );
    return [for (final row in rows) row['profile_id']! as String];
  }

  @override
  Future<void> reassignProfile({
    required String fromProfileId,
    required String toProfileId,
  }) async {
    if (fromProfileId == toProfileId) {
      return;
    }
    final db = await _open();
    await db.transaction((txn) async {
      // Drop the target's rows for the sources being moved, so the re-key can
      // never hit the (profile_id, source_id) primary key.
      await txn.delete(
        _tableImported,
        where:
            'profile_id = ? AND source_id IN '
            '(SELECT source_id FROM $_tableImported WHERE profile_id = ?)',
        whereArgs: [toProfileId, fromProfileId],
      );
      await txn.update(
        _tableImported,
        {'profile_id': toProfileId},
        where: 'profile_id = ?',
        whereArgs: [fromProfileId],
      );

      // Merged in Dart rather than with an UPSERT, which needs SQLite 3.24+
      // (unavailable on Android API 26–27).
      final syncRows = await txn.query(
        _tableSync,
        where: 'profile_id IN (?, ?)',
        whereArgs: [fromProfileId, toProfileId],
      );
      final timestamps = [
        for (final row in syncRows)
          if (DateTime.tryParse(row['last_sync_at']! as String) case final at?)
            at.toUtc(),
      ];
      await txn.delete(
        _tableSync,
        where: 'profile_id IN (?, ?)',
        whereArgs: [fromProfileId, toProfileId],
      );
      if (timestamps.isNotEmpty) {
        final latest = timestamps.reduce((a, b) => a.isAfter(b) ? a : b);
        await txn.insert(_tableSync, {
          'profile_id': toProfileId,
          'last_sync_at': latest.toIso8601String(),
        });
      }
    });
  }

  @override
  Future<void> markImported({
    required String profileId,
    required String sourceId,
    required String localActivityId,
  }) async {
    final db = await _open();
    await db.insert(_tableImported, {
      'profile_id': profileId,
      'source_id': sourceId,
      'local_activity_id': localActivityId,
      'imported_at': _now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> removeByLocalActivityId(String localActivityId) async {
    final db = await _open();
    await db.delete(
      _tableImported,
      where: 'local_activity_id = ?',
      whereArgs: [localActivityId],
    );
  }

  @override
  Future<void> clearForProfile(String profileId) async {
    final db = await _open();
    await db.transaction((txn) async {
      await txn.delete(
        _tableImported,
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
      await txn.delete(
        _tableSync,
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
    });
  }

  @override
  Future<List<HealthImportedWorkout>> listImported({
    required String profileId,
    required int offset,
    required int limit,
  }) async {
    final db = await _open();
    final rows = await db.query(
      _tableImported,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'imported_at DESC',
      offset: offset,
      limit: limit,
    );
    return rows
        .map(
          (row) => HealthImportedWorkout(
            sourceId: row['source_id'] as String,
            localActivityId: row['local_activity_id'] as String,
            importedAt: DateTime.parse(row['imported_at'] as String).toUtc(),
          ),
        )
        .toList();
  }

  @override
  Future<DateTime?> lastSyncAt(String profileId) async {
    final db = await _open();
    final rows = await db.query(
      _tableSync,
      columns: ['last_sync_at'],
      where: 'profile_id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['last_sync_at'] as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  @override
  Future<void> setLastSyncAt(String profileId, DateTime at) async {
    final db = await _open();
    await db.insert(_tableSync, {
      'profile_id': profileId,
      'last_sync_at': at.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
