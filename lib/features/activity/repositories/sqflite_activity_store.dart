import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/private_storage_paths.dart';
import 'package:endurain/core/utils/json_parsing.dart';
import 'package:endurain/core/utils/sqlite_migration_runner.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_store.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed [LocalActivityStore] implemented with sqflite.
///
/// Inject a custom databaseFactory and databasePath in tests:
/// ```dart
/// SqfliteActivityStore(
///   databaseFactory: databaseFactoryFfi,
///   databasePath: inMemoryDatabasePath,
/// )
/// ```
class SqfliteActivityStore implements LocalActivityStore {
  SqfliteActivityStore({DatabaseFactory? databaseFactory, String? databasePath})
    : _factory = databaseFactory ?? _platformFactory(),
      _path = databasePath;

  static const int _schemaVersion = 8;
  static const String _dbFileName = 'activity.db';
  static const String _tableVersion = 'schema_version';
  static const String _tableActivity = 'local_activity';

  final DatabaseFactory _factory;
  final String? _path;
  Database? _db;

  /// Ordered schema migrations keyed by the version they upgrade the database
  /// **to**. Migration `n` transforms a database at version `n - 1` into
  /// version `n`.
  ///
  /// Both fresh installs (`onCreate`) and existing databases (`onUpgrade`) run
  /// the same migration steps, so the schema is built by exactly one code path.
  /// To evolve the schema:
  ///   1. add a new entry keyed by the next integer (e.g. `8: _migrateToV8`),
  ///   2. bump [_schemaVersion] to match,
  ///   3. implement the migration with additive, idempotent-friendly DDL
  ///      (e.g. `ALTER TABLE ... ADD COLUMN`).
  /// Never edit a shipped migration — only append new ones. A missing migration
  /// for the target version fails loudly (see [SqliteMigrationRunner]).
  late final SqliteMigrationRunner _migrationRunner = SqliteMigrationRunner(
    migrations: {
      1: _migrateToV1,
      2: _migrateToV2,
      3: _migrateToV3,
      4: _migrateToV4,
      5: _migrateToV5,
      6: _migrateToV6,
      7: _migrateToV7,
      8: _migrateToV8,
    },
    recordVersion: _recordSchemaVersion,
  );

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
          // Fresh install: run every migration from 1..version so the schema
          // is produced by the same steps an upgrade would apply.
          await _migrationRunner.run(db, from: 0, to: version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _migrationRunner.run(db, from: oldVersion, to: newVersion);
        },
      ),
    );
    return _db!;
  }

  /// Persists the current schema [version] in [_tableVersion] (single-row).
  Future<void> _recordSchemaVersion(Database db, int version) async {
    await db.delete(_tableVersion);
    await db.insert(_tableVersion, {'version': version});
  }

  /// Initial schema (version 1): the schema-version bookkeeping table and the
  /// local activity metadata table.
  Future<void> _migrateToV1(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableVersion (
        version INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tableActivity (
        id                               TEXT PRIMARY KEY,
        activity_type                    TEXT NOT NULL,
        started_at                       TEXT NOT NULL,
        ended_at                         TEXT NOT NULL,
        elapsed_duration_seconds         INTEGER NOT NULL,
        distance_meters                  REAL NOT NULL,
        average_speed_meters_per_second  REAL,
        point_count                      INTEGER NOT NULL,
        gpx_file_name                    TEXT NOT NULL,
        upload_status                    TEXT NOT NULL,
        created_at                       TEXT NOT NULL,
        updated_at                       TEXT NOT NULL,
        uploaded_at                      TEXT,
        last_upload_attempt_at           TEXT,
        last_upload_error_code           TEXT,
        server_activity_id               TEXT
      )
    ''');
  }

  /// Schema version 2: adds the optional `idempotency_key` column used for
  /// stable server-side upload de-duplication (health imports derive it from
  /// the source workout UUID; GPS recordings leave it null and fall back to
  /// the record id).
  Future<void> _migrateToV2(Database db) async {
    await db.execute(
      'ALTER TABLE $_tableActivity ADD COLUMN idempotency_key TEXT',
    );
  }

  Future<void> _migrateToV3(Database db) async {
    await db.execute(
      'ALTER TABLE $_tableActivity ADD COLUMN connection_origin TEXT',
    );
  }

  Future<void> _migrateToV4(Database db) async {
    await db.execute('ALTER TABLE $_tableActivity RENAME TO local_activity_v3');
    await db.execute('''
      CREATE TABLE $_tableActivity (
        id                               TEXT PRIMARY KEY,
        activity_type                    TEXT NOT NULL,
        started_at                       TEXT NOT NULL,
        ended_at                         TEXT NOT NULL,
        elapsed_duration_seconds         INTEGER NOT NULL,
        distance_meters                  REAL NOT NULL,
        average_speed_meters_per_second  REAL,
        point_count                      INTEGER NOT NULL,
        gpx_file_name                    TEXT NOT NULL,
        upload_status                    TEXT NOT NULL,
        created_at                       TEXT NOT NULL,
        updated_at                       TEXT NOT NULL,
        uploaded_at                      TEXT,
        last_upload_attempt_at           TEXT,
        last_upload_error_code           TEXT,
        idempotency_key                  TEXT,
        connection_origin                TEXT
      )
    ''');
    await db.execute('''
      INSERT INTO $_tableActivity (
        id, activity_type, started_at, ended_at,
        elapsed_duration_seconds, distance_meters,
        average_speed_meters_per_second, point_count,
        gpx_file_name, upload_status, created_at, updated_at,
        uploaded_at, last_upload_attempt_at, last_upload_error_code,
        idempotency_key, connection_origin
      )
      SELECT
        id, activity_type, started_at, ended_at,
        elapsed_duration_seconds, distance_meters,
        average_speed_meters_per_second, point_count,
        gpx_file_name, upload_status, created_at, updated_at,
        uploaded_at, last_upload_attempt_at, last_upload_error_code,
        idempotency_key, connection_origin
      FROM local_activity_v3
    ''');
    await db.execute('DROP TABLE local_activity_v3');
  }

  Future<void> _migrateToV5(Database db) async {
    await db.execute(
      'ALTER TABLE $_tableActivity ADD COLUMN connection_profile_id TEXT',
    );
  }

  Future<void> _migrateToV6(Database db) async {
    await db.execute(
      'ALTER TABLE $_tableActivity '
      'ADD COLUMN auto_retry_eligible INTEGER NOT NULL DEFAULT 1',
    );
  }

  Future<void> _migrateToV7(Database db) async {
    await db.execute(
      'ALTER TABLE $_tableActivity '
      'ADD COLUMN gpx_cleanup_pending INTEGER NOT NULL DEFAULT 0',
    );
  }

  /// Schema version 8: adds the optional richer-summary metrics surfaced in the
  /// post-recording summary and activity details — the fastest observed speed
  /// and total ascent. Both are null for activities recorded before this
  /// migration and for imports without the underlying track data.
  Future<void> _migrateToV8(Database db) async {
    await db.execute(
      'ALTER TABLE $_tableActivity '
      'ADD COLUMN max_speed_meters_per_second REAL',
    );
    await db.execute(
      'ALTER TABLE $_tableActivity ADD COLUMN elevation_gain_meters REAL',
    );
  }

  @override
  Future<List<LocalActivityRecord>> list() async {
    final db = await _open();
    final rows = await db.query(_tableActivity, orderBy: 'ended_at DESC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<LocalActivityRecord?> get(String id) async {
    final db = await _open();
    final rows = await db.query(
      _tableActivity,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<LocalActivityRecord>> getByIds(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    final db = await _open();
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.query(
      _tableActivity,
      where: 'id IN ($placeholders)',
      whereArgs: ids.toList(),
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> upsert(LocalActivityRecord record) async {
    final db = await _open();
    await db.insert(
      _tableActivity,
      _toRow(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<bool> updateIfPresent(LocalActivityRecord record) async {
    final db = await _open();
    return await db.update(
          _tableActivity,
          _toRow(record),
          where: 'id = ?',
          whereArgs: [record.id],
        ) >
        0;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _open();
    await db.delete(_tableActivity, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<LocalActivityRecord>> listPage({
    required int offset,
    required int limit,
  }) async {
    final db = await _open();
    final rows = await db.query(
      _tableActivity,
      orderBy: 'ended_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<int> count() async {
    final db = await _open();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_tableActivity',
    );
    return result.first['c'] as int? ?? 0;
  }

  @override
  Future<int> bindUnassignedToProfile({
    required String origin,
    required String profileId,
    required DateTime updatedAt,
  }) async {
    final db = await _open();
    return db.update(
      _tableActivity,
      {
        'connection_origin': origin,
        'connection_profile_id': profileId,
        'updated_at': updatedAt.toUtcIso8601(),
      },
      where: 'connection_origin IS NULL AND connection_profile_id IS NULL',
    );
  }

  @override
  Future<List<LocalActivityRecord>> listByUploadStatus(
    Set<LocalActivityUploadStatus> statuses,
  ) async {
    if (statuses.isEmpty) {
      return const <LocalActivityRecord>[];
    }
    final db = await _open();
    final values = statuses.map((status) => status.toJson()).toList();
    final placeholders = List.filled(values.length, '?').join(', ');
    final rows = await db.query(
      _tableActivity,
      where: 'upload_status IN ($placeholders)',
      whereArgs: values,
      orderBy: 'ended_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Map<String, Object?> _toRow(LocalActivityRecord r) {
    return {
      'id': r.id,
      'activity_type': r.activityType.apiValue,
      'started_at': r.startedAt.toUtcIso8601(),
      'ended_at': r.endedAt.toUtcIso8601(),
      'elapsed_duration_seconds': r.elapsedDurationSeconds,
      'distance_meters': r.distanceMeters,
      'average_speed_meters_per_second': r.averageSpeedMetersPerSecond,
      'max_speed_meters_per_second': r.maxSpeedMetersPerSecond,
      'elevation_gain_meters': r.elevationGainMeters,
      'point_count': r.pointCount,
      'gpx_file_name': r.gpxFileName,
      'upload_status': r.uploadStatus.toJson(),
      'created_at': r.createdAt.toUtcIso8601(),
      'updated_at': r.updatedAt.toUtcIso8601(),
      'uploaded_at': r.uploadedAt?.toUtcIso8601(),
      'last_upload_attempt_at': r.lastUploadAttemptAt?.toUtcIso8601(),
      'last_upload_error_code': r.lastUploadErrorCode?.name,
      'auto_retry_eligible': r.autoRetryEligible ? 1 : 0,
      'gpx_cleanup_pending': r.gpxCleanupPending ? 1 : 0,
      'idempotency_key': r.idempotencyKey,
      'connection_origin': r.connectionOrigin,
      'connection_profile_id': r.connectionProfileId,
    };
  }

  LocalActivityRecord _fromRow(Map<String, Object?> row) {
    return LocalActivityRecord(
      id: row['id'] as String,
      activityType: ActivityType.fromApiValue(jsonString(row['activity_type'])),
      startedAt: jsonDateTime(row['started_at'])!,
      endedAt: jsonDateTime(row['ended_at'])!,
      elapsedDurationSeconds: row['elapsed_duration_seconds'] as int,
      distanceMeters: (row['distance_meters'] as num).toDouble(),
      averageSpeedMetersPerSecond:
          (row['average_speed_meters_per_second'] as num?)?.toDouble(),
      maxSpeedMetersPerSecond: (row['max_speed_meters_per_second'] as num?)
          ?.toDouble(),
      elevationGainMeters: (row['elevation_gain_meters'] as num?)?.toDouble(),
      pointCount: row['point_count'] as int,
      gpxFileName: row['gpx_file_name'] as String,
      uploadStatus: LocalActivityUploadStatus.fromJson(row['upload_status']),
      createdAt: jsonDateTime(row['created_at'])!,
      updatedAt: jsonDateTime(row['updated_at'])!,
      uploadedAt: jsonDateTime(row['uploaded_at']),
      lastUploadAttemptAt: jsonDateTime(row['last_upload_attempt_at']),
      lastUploadErrorCode: _errorCode(row['last_upload_error_code']),
      autoRetryEligible: (row['auto_retry_eligible'] as int? ?? 1) == 1,
      gpxCleanupPending: (row['gpx_cleanup_pending'] as int? ?? 0) == 1,
      idempotencyKey: row['idempotency_key'] as String?,
      connectionOrigin: row['connection_origin'] as String?,
      connectionProfileId: row['connection_profile_id'] as String?,
    );
  }

  AppErrorCode? _errorCode(Object? value) => appErrorCodeByName(value);
}
