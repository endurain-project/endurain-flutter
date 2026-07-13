import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/sqflite_health_import_store.dart';

void main() {
  const origin = 'https://example.test';
  setUpAll(() {
    sqfliteFfiInit();
  });

  HealthImportRepository makeRepo() => HealthImportRepository(
    store: SqfliteHealthImportStore(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    ),
  );

  group('HealthImportRepository', () {
    test('isImported delegates to store', () async {
      final repo = makeRepo();
      await repo.markImported(
        origin: origin,
        sourceId: 'uuid-x',
        localActivityId: 'local-y',
      );
      expect(await repo.isImported(origin: origin, sourceId: 'uuid-x'), isTrue);
      expect(
        await repo.isImported(origin: origin, sourceId: 'uuid-z'),
        isFalse,
      );
    });

    test('lastSyncAt / setLastSyncAt delegate to store', () async {
      final repo = makeRepo();
      expect(await repo.lastSyncAt(origin), isNull);
      final ts = DateTime.utc(2025, 6, 3, 8, 0);
      await repo.setLastSyncAt(origin, ts);
      expect(await repo.lastSyncAt(origin), ts);
    });
  });
}
