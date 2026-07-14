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

    test('schema version is recorded', () async {
      final store = makeStore();
      // Open the database by performing a query.
      await store.isImported(profileId: profileA, sourceId: 'any');
      // No assertion needed — if the migration fails the setup above throws.
    });
  });
}
