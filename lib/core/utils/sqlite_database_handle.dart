import 'dart:async';

import 'package:endurain/core/utils/private_storage_paths.dart';
import 'package:endurain/core/utils/sqlite_migration_runner.dart';
import 'package:sqflite/sqflite.dart';

/// Lazily opens, migrates and caches one app-private SQLite database.
///
/// Fresh installs (`onCreate`) and upgrades (`onUpgrade`) both go through the
/// [SqliteMigrationRunner], so the schema is produced by a single code path.
/// The open [Future] is cached, so concurrent first calls to `open` share one
/// `openDatabase` instead of racing to open the file twice. A failed open is
/// not cached: the next call retries.
///
/// Inject `databaseFactory` and `databasePath` in tests (for example
/// `databaseFactoryFfi` with `inMemoryDatabasePath`).
class SqliteDatabaseHandle {
  SqliteDatabaseHandle({
    required this.fileName,
    required this.schemaVersion,
    required SqliteMigrationRunner migrationRunner,
    DatabaseFactory? databaseFactory,
    String? databasePath,
  }) : _factory = databaseFactory ?? databaseFactorySqflitePlugin,
       _path = databasePath,
       _migrationRunner = migrationRunner;

  /// File name under the private database directory (ignored when a
  /// `databasePath` was injected).
  final String fileName;

  /// Target schema version handed to sqflite.
  final int schemaVersion;

  final DatabaseFactory _factory;
  final String? _path;
  final SqliteMigrationRunner _migrationRunner;
  Database? _database;
  Future<Database>? _opening;

  /// Returns the shared database, opening it on first use.
  ///
  /// The in-flight open is cached only while it runs; the opened [Database]
  /// is cached afterwards, so this handle stays sendable once opened.
  Future<Database> open() {
    final database = _database;
    if (database != null) return Future<Database>.value(database);
    return _opening ??= _openDatabase().then(
      (opened) {
        _database = opened;
        _opening = null;
        return opened;
      },
      onError: (Object error, StackTrace stackTrace) {
        _opening = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  Future<Database> _openDatabase() async {
    final path =
        _path ??
        await privateDatabasePath(
          databaseFactory: _factory,
          fileName: fileName,
        );
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, version) =>
            _migrationRunner.run(db, from: 0, to: version),
        onUpgrade: (db, oldVersion, newVersion) =>
            _migrationRunner.run(db, from: oldVersion, to: newVersion),
      ),
    );
  }

  /// Closes the database if it was opened. A later `open` reopens it.
  Future<void> close() async {
    final opening = _opening;
    final database = _database;
    _opening = null;
    _database = null;
    try {
      await (database ?? await opening)?.close();
    } catch (_) {
      // The open itself failed; there is nothing to close.
    }
  }
}
