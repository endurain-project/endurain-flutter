import 'package:endurain/core/utils/sqlite_migration_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<Database> openDb() => databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: 1),
  );

  test('applies migrations in ascending order then records once', () async {
    final db = await openDb();
    addTearDown(db.close);
    final applied = <int>[];
    final recorded = <int>[];
    final runner = SqliteMigrationRunner(
      migrations: {
        1: (db) async {
          applied.add(1);
        },
        2: (db) async {
          applied.add(2);
        },
        3: (db) async {
          applied.add(3);
        },
      },
      recordVersion: (db, version) async {
        recorded.add(version);
      },
    );

    await runner.run(db, from: 0, to: 3);

    expect(applied, [1, 2, 3]);
    expect(recorded, [3], reason: 'records only the final version, once');
  });

  test('runs only the migrations in the (from, to] range', () async {
    final db = await openDb();
    addTearDown(db.close);
    final applied = <int>[];
    final runner = SqliteMigrationRunner(
      migrations: {
        1: (db) async {
          applied.add(1);
        },
        2: (db) async {
          applied.add(2);
        },
        3: (db) async {
          applied.add(3);
        },
      },
      recordVersion: (db, version) async {},
    );

    await runner.run(db, from: 1, to: 3);

    expect(applied, [2, 3]);
  });

  test(
    'throws when a migration in range is missing, recording nothing',
    () async {
      final db = await openDb();
      addTearDown(db.close);
      var recorded = false;
      final runner = SqliteMigrationRunner(
        migrations: {
          1: (db) async {},
          // Version 2 intentionally omitted.
          3: (db) async {},
        },
        recordVersion: (db, version) async {
          recorded = true;
        },
      );

      await expectLater(
        runner.run(db, from: 0, to: 3),
        throwsA(isA<StateError>()),
      );
      expect(recorded, isFalse, reason: 'never records an incomplete schema');
    },
  );

  test('records nothing when there is no version change', () async {
    final db = await openDb();
    addTearDown(db.close);
    var recorded = false;
    final runner = SqliteMigrationRunner(
      migrations: const {},
      recordVersion: (db, version) async {
        recorded = true;
      },
    );

    await runner.run(db, from: 3, to: 3);

    expect(recorded, isFalse);
  });
}
