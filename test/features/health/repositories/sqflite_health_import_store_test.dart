import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:endurain/features/health/repositories/sqflite_health_import_store.dart';

void main() {
  const profileA = 'profile-a';
  const profileB = 'profile-b';

  setUpAll(() {
    sqfliteFfiInit();
  });

  SqfliteHealthImportStore makeStore() => SqfliteHealthImportStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: inMemoryDatabasePath,
  );

  group('SqfliteHealthImportStore', () {
    test('isImported returns false for unknown sourceId', () async {
      final store = makeStore();
      expect(
        await store.isImported(profileId: profileA, sourceId: 'unknown-uuid'),
        isFalse,
      );
    });

    test('markImported + isImported round-trip', () async {
      final store = makeStore();
      await store.markImported(
        profileId: profileA,
        sourceId: 'uuid-1',
        localActivityId: 'local-a',
      );
      expect(
        await store.isImported(profileId: profileA, sourceId: 'uuid-1'),
        isTrue,
      );
      expect(
        await store.isImported(profileId: profileA, sourceId: 'uuid-2'),
        isFalse,
      );
      expect(
        await store.isImported(profileId: profileB, sourceId: 'uuid-1'),
        isFalse,
      );
    });

    test('markImported is idempotent', () async {
      final store = makeStore();
      await store.markImported(
        profileId: profileA,
        sourceId: 'uuid-1',
        localActivityId: 'local-a',
      );
      // Second call must not throw.
      await expectLater(
        store.markImported(
          profileId: profileA,
          sourceId: 'uuid-1',
          localActivityId: 'local-a',
        ),
        completes,
      );
      expect(
        await store.isImported(profileId: profileA, sourceId: 'uuid-1'),
        isTrue,
      );
    });

    test('removeByLocalActivityId makes a workout importable again', () async {
      final store = makeStore();
      await store.markImported(
        profileId: profileA,
        sourceId: 'uuid-1',
        localActivityId: 'local-a',
      );

      await store.removeByLocalActivityId('local-a');

      expect(
        await store.isImported(profileId: profileA, sourceId: 'uuid-1'),
        isFalse,
      );
    });

    test('clearForProfile leaves another profile intact', () async {
      final store = makeStore();
      await store.markImported(
        profileId: profileA,
        sourceId: 'uuid-1',
        localActivityId: 'local-a',
      );
      await store.markImported(
        profileId: profileB,
        sourceId: 'uuid-1',
        localActivityId: 'local-b',
      );

      await store.clearForProfile(profileA);

      expect(
        await store.isImported(profileId: profileA, sourceId: 'uuid-1'),
        isFalse,
      );
      expect(
        await store.isImported(profileId: profileB, sourceId: 'uuid-1'),
        isTrue,
      );
    });

    test('adopts a quarantined legacy marker into an explicit scope', () async {
      final store = makeStore();
      await store.markImported(
        profileId: 'legacy://unassigned',
        sourceId: 'uuid-legacy',
        localActivityId: 'local-legacy',
      );

      expect(
        await store.legacyLocalActivityIdFor('uuid-legacy'),
        'local-legacy',
      );
      await store.adoptLegacyImport(
        profileId: profileA,
        sourceId: 'uuid-legacy',
      );

      expect(
        await store.localActivityIdFor(
          profileId: profileA,
          sourceId: 'uuid-legacy',
        ),
        'local-legacy',
      );
      expect(await store.legacyLocalActivityIdFor('uuid-legacy'), isNull);
    });

    test('lists imported workouts newest-first with pagination', () async {
      final store = makeStore();
      await store.markImported(
        profileId: profileA,
        sourceId: 'uuid-1',
        localActivityId: 'local-1',
      );
      await Future<void>.delayed(const Duration(milliseconds: 1));
      await store.markImported(
        profileId: profileA,
        sourceId: 'uuid-2',
        localActivityId: 'local-2',
      );
      await store.markImported(
        profileId: profileB,
        sourceId: 'uuid-other',
        localActivityId: 'local-other',
      );

      final first = await store.listImported(
        profileId: profileA,
        offset: 0,
        limit: 1,
      );
      final second = await store.listImported(
        profileId: profileA,
        offset: 1,
        limit: 1,
      );

      expect(first.map((entry) => entry.sourceId), ['uuid-2']);
      expect(second.map((entry) => entry.sourceId), ['uuid-1']);
    });

    test('lastSyncAt returns null when never set', () async {
      final store = makeStore();
      expect(await store.lastSyncAt(profileA), isNull);
    });

    test('setLastSyncAt + lastSyncAt round-trip', () async {
      final store = makeStore();
      final ts = DateTime.utc(2025, 6, 1, 12, 0, 0);
      await store.setLastSyncAt(profileA, ts);
      final result = await store.lastSyncAt(profileA);
      expect(result, ts);
      expect(await store.lastSyncAt(profileB), isNull);
    });

    test('setLastSyncAt overwrites previous value', () async {
      final store = makeStore();
      final ts1 = DateTime.utc(2025, 6, 1);
      final ts2 = DateTime.utc(2025, 6, 2);
      await store.setLastSyncAt(profileA, ts1);
      await store.setLastSyncAt(profileA, ts2);
      expect(await store.lastSyncAt(profileA), ts2);
    });

    test(
      'fresh install builds the v3 schema with profile_id columns',
      () async {
        final dir = await Directory.systemTemp.createTemp('health_store_v3');
        addTearDown(() => dir.delete(recursive: true));
        final dbPath = '${dir.path}/health_import.db';
        final store = SqfliteHealthImportStore(
          databaseFactory: databaseFactoryFfi,
          databasePath: dbPath,
        );
        // Force the database open + migrations by issuing a query.
        await store.isImported(profileId: profileA, sourceId: 'any');

        final db = await databaseFactoryFfi.openDatabase(dbPath);
        addTearDown(db.close);
        final version = await db.query('schema_version');
        expect(version.first['version'], 3);
        for (final table in const ['imported_workouts', 'sync_state']) {
          final columns = await db.rawQuery('PRAGMA table_info($table)');
          final names = columns.map((column) => column['name']).toSet();
          expect(names, contains('profile_id'));
          expect(names, isNot(contains('origin')));
        }
      },
    );

    test('upgrades a v2 database to v3, preserving data', () async {
      final dir = await Directory.systemTemp.createTemp('health_store_v2');
      addTearDown(() => dir.delete(recursive: true));
      final dbPath = '${dir.path}/health_import.db';

      // Build a v2-schema database (origin columns) with a scoped row and a
      // last-sync timestamp, exactly as a shipped v2 build would leave it.
      final legacy = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE schema_version '
              '(id INTEGER PRIMARY KEY, version INTEGER NOT NULL)',
            );
            await db.execute(
              'INSERT OR REPLACE INTO schema_version (id, version) '
              'VALUES (1, 2)',
            );
            await db.execute(
              'CREATE TABLE imported_workouts ('
              'origin TEXT NOT NULL, source_id TEXT NOT NULL, '
              'local_activity_id TEXT NOT NULL, imported_at TEXT NOT NULL, '
              'PRIMARY KEY (origin, source_id))',
            );
            await db.execute(
              'CREATE INDEX imported_workouts_local_id_idx '
              'ON imported_workouts (local_activity_id)',
            );
            await db.execute(
              'CREATE TABLE sync_state '
              '(origin TEXT PRIMARY KEY, last_sync_at TEXT NOT NULL)',
            );
            await db.insert('imported_workouts', {
              'origin': profileA,
              'source_id': 'uuid-1',
              'local_activity_id': 'local-a',
              'imported_at': '2026-01-01T00:00:00.000Z',
            });
            await db.insert('sync_state', {
              'origin': profileA,
              'last_sync_at': '2026-01-02T00:00:00.000Z',
            });
          },
        ),
      );
      await legacy.close();

      // Opening through the store runs the v3 upgrade.
      final store = SqfliteHealthImportStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath,
      );
      expect(
        await store.localActivityIdFor(profileId: profileA, sourceId: 'uuid-1'),
        'local-a',
      );
      expect(await store.lastSyncAt(profileA), DateTime.utc(2026, 1, 2));

      final db = await databaseFactoryFfi.openDatabase(dbPath);
      addTearDown(db.close);
      expect((await db.query('schema_version')).first['version'], 3);
      final columns = await db.rawQuery('PRAGMA table_info(imported_workouts)');
      final names = columns.map((column) => column['name']).toSet();
      expect(names, contains('profile_id'));
      expect(names, isNot(contains('origin')));
    });
  });
}
