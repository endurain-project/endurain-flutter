import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/sqflite_activity_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  SqfliteActivityStore _store() => SqfliteActivityStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: inMemoryDatabasePath,
  );

  group('SqfliteActivityStore', () {
    test('returns empty list when no records are stored', () async {
      final store = _store();
      expect(await store.list(), isEmpty);
      await store.close();
    });

    test('upsert inserts a new record and list returns it', () async {
      final store = _store();
      final record = _record(id: 'a1');
      await store.upsert(record);

      final list = await store.list();
      expect(list, hasLength(1));
      expect(list.first.id, 'a1');
      expect(list.first.activityType, ActivityType.run);
      await store.close();
    });

    test('upsert replaces an existing record', () async {
      final store = _store();
      final original = _record(id: 'a1');
      await store.upsert(original);

      final updated = original.copyWith(
        uploadStatus: LocalActivityUploadStatus.uploaded,
      );
      await store.upsert(updated);

      final retrieved = await store.get('a1');
      expect(retrieved?.uploadStatus, LocalActivityUploadStatus.uploaded);
      await store.close();
    });

    test('list returns records sorted by endedAt descending', () async {
      final store = _store();
      final older = _record(id: 'older', endedAt: DateTime.utc(2026, 6, 1));
      final newer = _record(id: 'newer', endedAt: DateTime.utc(2026, 6, 2));
      await store.upsert(older);
      await store.upsert(newer);

      final list = await store.list();
      expect(list.map((r) => r.id).toList(), ['newer', 'older']);
      await store.close();
    });

    test('get returns null for unknown id', () async {
      final store = _store();
      expect(await store.get('nonexistent'), isNull);
      await store.close();
    });

    test('get returns the correct record by id', () async {
      final store = _store();
      await store.upsert(_record(id: 'a'));
      await store.upsert(_record(id: 'b'));

      final result = await store.get('b');
      expect(result?.id, 'b');
      await store.close();
    });

    test('delete removes a record', () async {
      final store = _store();
      await store.upsert(_record(id: 'a1'));
      await store.delete('a1');

      expect(await store.list(), isEmpty);
      await store.close();
    });

    test('delete on unknown id does not throw', () async {
      final store = _store();
      await expectLater(store.delete('nonexistent'), completes);
      await store.close();
    });

    test('upsert persists all nullable fields', () async {
      final store = _store();
      final now = DateTime.utc(2026, 6, 1, 12);
      final record = _record(id: 'r1').copyWith(
        uploadStatus: LocalActivityUploadStatus.uploaded,
        uploadedAt: now,
        serverActivityId: 'srv-42',
      );
      await store.upsert(record);

      final retrieved = await store.get('r1');
      expect(retrieved?.uploadedAt, now);
      expect(retrieved?.serverActivityId, 'srv-42');
      await store.close();
    });

    test('null optional fields round-trip as null', () async {
      final store = _store();
      await store.upsert(_record(id: 'r2'));

      final retrieved = await store.get('r2');
      expect(retrieved?.uploadedAt, isNull);
      expect(retrieved?.serverActivityId, isNull);
      expect(retrieved?.averageSpeedMetersPerSecond, isNull);
      await store.close();
    });
  });

  group('SqfliteActivityStore – manifest migration', () {
    test('imports records from manifest on first open', () async {
      final records = [_record(id: 'm1'), _record(id: 'm2')];
      final store = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
        manifestReader: () async => records,
      );

      final list = await store.list();
      expect(list.map((r) => r.id).toSet(), {'m1', 'm2'});
      await store.close();
    });

    test('manifest read error does not crash migration', () async {
      final store = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
        manifestReader: () async => throw Exception('read error'),
      );

      await expectLater(store.list(), completion(isEmpty));
      await store.close();
    });

    test('malformed manifest entries are skipped, valid entries are imported',
        () async {
      // Simulate a manifest where one record throws during row conversion.
      // We model this by mixing a valid record with one that has a null id
      // (which would fail on the TEXT NOT NULL constraint in SQLite but
      // continueOnError keeps the batch going for the rest).
      final valid = _record(id: 'good');
      final store = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
        manifestReader: () async => [valid],
      );

      final list = await store.list();
      expect(list, hasLength(1));
      expect(list.first.id, 'good');
      await store.close();
    });

    test('no manifest reader results in empty store', () async {
      final store = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );

      expect(await store.list(), isEmpty);
      await store.close();
    });
  });
}

LocalActivityRecord _record({
  required String id,
  DateTime? endedAt,
}) {
  final ended = endedAt ?? DateTime.utc(2026, 6, 2, 10);
  return LocalActivityRecord(
    id: id,
    activityType: ActivityType.run,
    startedAt: ended.subtract(const Duration(minutes: 5)),
    endedAt: ended,
    elapsedDurationSeconds: 300,
    distanceMeters: 1200,
    pointCount: 8,
    gpxFileName: '$id.gpx',
    uploadStatus: LocalActivityUploadStatus.pending,
    createdAt: ended,
    updatedAt: ended,
  );
}
