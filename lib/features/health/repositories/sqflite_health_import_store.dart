import 'package:endurain/features/health/repositories/health_import_store.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/core/utils/private_storage_paths.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed [HealthImportStore] implemented with sqflite.
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
  }) : _factory = databaseFactory ?? _platformFactory(),
       _path = databasePath;

  static const int _schemaVersion = 2;
  static const String _dbFileName = 'health_import.db';
  static const String _tableVersion = 'schema_version';
  static const String _tableImported = 'imported_workouts';
  static const String _tableSync = 'sync_state';
  static const String _legacyOrigin = 'legacy://unassigned';

  final DatabaseFactory _factory;
  final String? _path;
  Database? _db;

  late final Map<int, Future<void> Function(Database)> _migrations = {
    1: _migrateToV1,
    2: _migrateToV2,
  };

  static DatabaseFactory _platformFactory() => databaseFactorySqflitePlugin;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final path =
        _path ??
        await privateDatabasePath(
          databaseFactory: _factory,
          fileName: _dbFileName,
        );
    _db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onCreate: (db, version) async {
          await _runMigrations(db, from: 0, to: version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _runMigrations(db, from: oldVersion, to: newVersion);
        },
      ),
    );
    return _db!;
  }

  Future<void> _runMigrations(
    Database db, {
    required int from,
    required int to,
  }) async {
    for (var version = from + 1; version <= to; version++) {
      final migration = _migrations[version];
      if (migration != null) await migration(db);
      await db.execute(
        'INSERT OR REPLACE INTO $_tableVersion (id, version) VALUES (1, ?)',
        [version],
      );
    }
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
      [_legacyOrigin],
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
        'origin': _legacyOrigin,
        'last_sync_at': legacySync.first['value'],
      });
    }
    await db.execute('DROP TABLE key_value');
    await db.execute(
      'CREATE INDEX imported_workouts_local_id_idx '
      'ON $_tableImported (local_activity_id)',
    );
  }

  // ── HealthImportStore ───────────────────────────────────────────────────

  @override
  Future<bool> isImported({
    required String origin,
    required String sourceId,
  }) async {
    return await localActivityIdFor(origin: origin, sourceId: sourceId) != null;
  }

  @override
  Future<String?> localActivityIdFor({
    required String origin,
    required String sourceId,
  }) async {
    final db = await _open();
    final rows = await db.query(
      _tableImported,
      columns: ['local_activity_id'],
      where: 'origin = ? AND source_id = ?',
      whereArgs: [origin, sourceId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return rows.first['local_activity_id'] as String?;
    }
    return null;
  }

  @override
  Future<String?> legacyLocalActivityIdFor(String sourceId) async {
    final db = await _open();
    final legacyRows = await db.query(
      _tableImported,
      columns: ['local_activity_id'],
      where: 'origin = ? AND source_id = ?',
      whereArgs: [_legacyOrigin, sourceId],
      limit: 1,
    );
    return legacyRows.isEmpty
        ? null
        : legacyRows.first['local_activity_id'] as String?;
  }

  @override
  Future<void> adoptLegacyImport({
    required String origin,
    required String sourceId,
  }) async {
    final db = await _open();
    await db.update(
      _tableImported,
      {'origin': origin},
      where: 'origin = ? AND source_id = ?',
      whereArgs: [_legacyOrigin, sourceId],
    );
  }

  @override
  Future<void> markImported({
    required String origin,
    required String sourceId,
    required String localActivityId,
  }) async {
    final db = await _open();
    await db.insert(_tableImported, {
      'origin': origin,
      'source_id': sourceId,
      'local_activity_id': localActivityId,
      'imported_at': DateTime.now().toUtc().toIso8601String(),
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
  Future<void> clearOrigin(String origin) async {
    final db = await _open();
    await db.transaction((txn) async {
      await txn.delete(
        _tableImported,
        where: 'origin = ?',
        whereArgs: [origin],
      );
      await txn.delete(_tableSync, where: 'origin = ?', whereArgs: [origin]);
    });
  }

  @override
  Future<List<HealthImportedWorkout>> listImported({
    required String origin,
    required int offset,
    required int limit,
  }) async {
    final db = await _open();
    final rows = await db.query(
      _tableImported,
      where: 'origin = ?',
      whereArgs: [origin],
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
  Future<DateTime?> lastSyncAt(String origin) async {
    final db = await _open();
    final rows = await db.query(
      _tableSync,
      columns: ['last_sync_at'],
      where: 'origin = ?',
      whereArgs: [origin],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['last_sync_at'] as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  @override
  Future<void> setLastSyncAt(String origin, DateTime at) async {
    final db = await _open();
    await db.insert(_tableSync, {
      'origin': origin,
      'last_sync_at': at.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
