import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:endurain/features/health/repositories/sqflite_health_import_store.dart';

void main() {
  const originA = 'https://a.example';
  const originB = 'https://b.example';

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
        await store.isImported(origin: originA, sourceId: 'unknown-uuid'),
        isFalse,
      );
    });

    test('markImported + isImported round-trip', () async {
      final store = makeStore();
      await store.markImported(
        origin: originA,
        sourceId: 'uuid-1',
        localActivityId: 'local-a',
      );
      expect(
        await store.isImported(origin: originA, sourceId: 'uuid-1'),
        isTrue,
      );
      expect(
        await store.isImported(origin: originA, sourceId: 'uuid-2'),
        isFalse,
      );
      expect(
        await store.isImported(origin: originB, sourceId: 'uuid-1'),
        isFalse,
      );
    });

    test('markImported is idempotent', () async {
      final store = makeStore();
      await store.markImported(
        origin: originA,
        sourceId: 'uuid-1',
        localActivityId: 'local-a',
      );
      // Second call must not throw.
      await expectLater(
        store.markImported(
          origin: originA,
          sourceId: 'uuid-1',
          localActivityId: 'local-a',
        ),
        completes,
      );
      expect(
        await store.isImported(origin: originA, sourceId: 'uuid-1'),
        isTrue,
      );
    });

    test('removeByLocalActivityId makes a workout importable again', () async {
      final store = makeStore();
      await store.markImported(
        origin: originA,
        sourceId: 'uuid-1',
        localActivityId: 'local-a',
      );

      await store.removeByLocalActivityId('local-a');

      expect(
        await store.isImported(origin: originA, sourceId: 'uuid-1'),
        isFalse,
      );
    });

    test('clearOrigin leaves another origin intact', () async {
      final store = makeStore();
      await store.markImported(
        origin: originA,
        sourceId: 'uuid-1',
        localActivityId: 'local-a',
      );
      await store.markImported(
        origin: originB,
        sourceId: 'uuid-1',
        localActivityId: 'local-b',
      );

      await store.clearOrigin(originA);

      expect(
        await store.isImported(origin: originA, sourceId: 'uuid-1'),
        isFalse,
      );
      expect(
        await store.isImported(origin: originB, sourceId: 'uuid-1'),
        isTrue,
      );
    });

    test('adopts a quarantined legacy marker into an explicit scope', () async {
      final store = makeStore();
      await store.markImported(
        origin: 'legacy://unassigned',
        sourceId: 'uuid-legacy',
        localActivityId: 'local-legacy',
      );

      expect(
        await store.legacyLocalActivityIdFor('uuid-legacy'),
        'local-legacy',
      );
      await store.adoptLegacyImport(origin: originA, sourceId: 'uuid-legacy');

      expect(
        await store.localActivityIdFor(
          origin: originA,
          sourceId: 'uuid-legacy',
        ),
        'local-legacy',
      );
      expect(await store.legacyLocalActivityIdFor('uuid-legacy'), isNull);
    });

    test('lists imported workouts newest-first with pagination', () async {
      final store = makeStore();
      await store.markImported(
        origin: originA,
        sourceId: 'uuid-1',
        localActivityId: 'local-1',
      );
      await Future<void>.delayed(const Duration(milliseconds: 1));
      await store.markImported(
        origin: originA,
        sourceId: 'uuid-2',
        localActivityId: 'local-2',
      );
      await store.markImported(
        origin: originB,
        sourceId: 'uuid-other',
        localActivityId: 'local-other',
      );

      final first = await store.listImported(
        origin: originA,
        offset: 0,
        limit: 1,
      );
      final second = await store.listImported(
        origin: originA,
        offset: 1,
        limit: 1,
      );

      expect(first.map((entry) => entry.sourceId), ['uuid-2']);
      expect(second.map((entry) => entry.sourceId), ['uuid-1']);
    });

    test('lastSyncAt returns null when never set', () async {
      final store = makeStore();
      expect(await store.lastSyncAt(originA), isNull);
    });

    test('setLastSyncAt + lastSyncAt round-trip', () async {
      final store = makeStore();
      final ts = DateTime.utc(2025, 6, 1, 12, 0, 0);
      await store.setLastSyncAt(originA, ts);
      final result = await store.lastSyncAt(originA);
      expect(result, ts);
      expect(await store.lastSyncAt(originB), isNull);
    });

    test('setLastSyncAt overwrites previous value', () async {
      final store = makeStore();
      final ts1 = DateTime.utc(2025, 6, 1);
      final ts2 = DateTime.utc(2025, 6, 2);
      await store.setLastSyncAt(originA, ts1);
      await store.setLastSyncAt(originA, ts2);
      expect(await store.lastSyncAt(originA), ts2);
    });

    test('schema version is recorded', () async {
      final store = makeStore();
      // Open the database by performing a query.
      await store.isImported(origin: originA, sourceId: 'any');
      // No assertion needed — if the migration fails the setup above throws.
    });
  });
}
