import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/json_parsing.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_store.dart';
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  SqfliteActivityStore({
    DatabaseFactory? databaseFactory,
    String? databasePath,
  }) : _factory = databaseFactory ?? _platformFactory(),
       _path = databasePath;

  static const int _schemaVersion = 1;
  static const String _dbFileName = 'activity.db';
  static const String _tableVersion = 'schema_version';
  static const String _tableActivity = 'local_activity';

  final DatabaseFactory _factory;
  final String? _path;
  Database? _db;

  static DatabaseFactory _platformFactory() {
    if (Platform.isAndroid || Platform.isIOS) {
      return databaseFactorySqflitePlugin;
    }
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final path =
        _path ?? '${await _factory.getDatabasesPath()}${Platform.pathSeparator}$_dbFileName';
    _db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableVersion (
              version INTEGER NOT NULL
            )
          ''');
          await db.insert(_tableVersion, {'version': version});
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
        },
      ),
    );
    return _db!;
  }

  @override
  Future<List<LocalActivityRecord>> list() async {
    final db = await _open();
    final rows = await db.query(
      _tableActivity,
      orderBy: 'ended_at DESC',
    );
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
  Future<void> upsert(LocalActivityRecord record) async {
    final db = await _open();
    await db.insert(
      _tableActivity,
      _toRow(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _open();
    await db.delete(_tableActivity, where: 'id = ?', whereArgs: [id]);
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
      'point_count': r.pointCount,
      'gpx_file_name': r.gpxFileName,
      'upload_status': r.uploadStatus.toJson(),
      'created_at': r.createdAt.toUtcIso8601(),
      'updated_at': r.updatedAt.toUtcIso8601(),
      'uploaded_at': r.uploadedAt?.toUtcIso8601(),
      'last_upload_attempt_at': r.lastUploadAttemptAt?.toUtcIso8601(),
      'last_upload_error_code': r.lastUploadErrorCode?.name,
      'server_activity_id': r.serverActivityId,
    };
  }

  LocalActivityRecord _fromRow(Map<String, Object?> row) {
    return LocalActivityRecord(
      id: row['id'] as String,
      activityType: ActivityType.fromApiValue(
        jsonString(row['activity_type']),
      ),
      startedAt: jsonDateTime(row['started_at'])!,
      endedAt: jsonDateTime(row['ended_at'])!,
      elapsedDurationSeconds: row['elapsed_duration_seconds'] as int,
      distanceMeters: (row['distance_meters'] as num).toDouble(),
      averageSpeedMetersPerSecond:
          (row['average_speed_meters_per_second'] as num?)?.toDouble(),
      pointCount: row['point_count'] as int,
      gpxFileName: row['gpx_file_name'] as String,
      uploadStatus: LocalActivityUploadStatus.fromJson(
        row['upload_status'],
      ),
      createdAt: jsonDateTime(row['created_at'])!,
      updatedAt: jsonDateTime(row['updated_at'])!,
      uploadedAt: jsonDateTime(row['uploaded_at']),
      lastUploadAttemptAt: jsonDateTime(row['last_upload_attempt_at']),
      lastUploadErrorCode: _errorCode(row['last_upload_error_code']),
      serverActivityId: row['server_activity_id'] as String?,
    );
  }

  AppErrorCode? _errorCode(Object? value) {
    if (value is! String) return null;
    for (final code in AppErrorCode.values) {
      if (code.name == value) return code;
    }
    return null;
  }
}
