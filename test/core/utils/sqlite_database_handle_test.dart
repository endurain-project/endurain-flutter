import 'package:endurain/core/utils/sqlite_database_handle.dart';
import 'package:endurain/core/utils/sqlite_migration_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('SqliteDatabaseHandle', () {
    late int migrationRuns;
    late SqliteMigrationRunner runner;

    setUp(() {
      migrationRuns = 0;
      runner = SqliteMigrationRunner(
        migrations: {
          1: (db) async {
            migrationRuns++;
            await db.execute('CREATE TABLE t (id INTEGER)');
          },
        },
        recordVersion: (db, version) async {},
      );
    });

    SqliteDatabaseHandle handle() => SqliteDatabaseHandle(
      fileName: 'test.db',
      schemaVersion: 1,
      migrationRunner: runner,
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );

    test('concurrent first calls share one opened database', () async {
      final h = handle();
      addTearDown(h.close);

      final results = await Future.wait([h.open(), h.open(), h.open()]);

      expect(identical(results[0], results[1]), isTrue);
      expect(identical(results[0], results[2]), isTrue);
      expect(migrationRuns, 1);
    });

    test('close then open reopens the database', () async {
      final h = handle();
      final first = await h.open();
      await h.close();

      final second = await h.open();
      addTearDown(h.close);

      expect(identical(first, second), isFalse);
      expect(migrationRuns, 2);
    });

    test('close without open is a no-op', () async {
      await handle().close();
    });
  });
}
