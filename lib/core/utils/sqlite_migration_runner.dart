import 'package:sqflite/sqflite.dart';

/// A single forward-only schema migration, keyed by the version it produces.
///
/// Migration `n` transforms a database at version `n - 1` into version `n`.
typedef SqliteMigration = Future<void> Function(Database db);

/// Applies ordered, forward-only SQLite schema migrations.
///
/// [run] executes every migration whose target version falls in the half-open
/// range `(from, to]`, in ascending order, then records the resulting version
/// once via `recordVersion`. sqflite wraps `onCreate`/`onUpgrade` in a
/// transaction, so a failure part-way through rolls back the whole batch and
/// the recorded version is never advanced past a partially-applied schema.
///
/// A missing migration for a version in range throws [StateError] instead of
/// being silently skipped: bumping the schema version without appending the
/// matching migration then fails loudly at open time rather than recording an
/// incomplete schema that corrupts later reads.
class SqliteMigrationRunner {
  const SqliteMigrationRunner({
    required Map<int, SqliteMigration> migrations,
    required Future<void> Function(Database db, int version) recordVersion,
  }) : _migrations = migrations,
       _recordVersion = recordVersion;

  final Map<int, SqliteMigration> _migrations;
  final Future<void> Function(Database db, int version) _recordVersion;

  /// Migrates [db] from version [from] to version [to].
  ///
  /// Pass `from: 0` from `onCreate` so a fresh install is built by the same
  /// steps an upgrade would apply.
  Future<void> run(Database db, {required int from, required int to}) async {
    for (var version = from + 1; version <= to; version++) {
      final migration = _migrations[version];
      if (migration == null) {
        throw StateError(
          'Missing SQLite migration for schema version $version.',
        );
      }
      await migration(db);
    }
    if (to > from) {
      await _recordVersion(db, to);
    }
  }
}
