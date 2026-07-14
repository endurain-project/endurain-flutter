import 'dart:io';

import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/sqflite_activity_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  SqfliteActivityStore makeStore() => SqfliteActivityStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: inMemoryDatabasePath,
  );

  group('SqfliteActivityStore', () {
    test('returns empty list when no records are stored', () async {
      final store = makeStore();
      expect(await store.list(), isEmpty);
      await store.close();
    });

    test('upsert inserts a new record and list returns it', () async {
      final store = makeStore();
      final record = _record(id: 'a1');
      await store.upsert(record);

      final list = await store.list();
      expect(list, hasLength(1));
      expect(list.first.id, 'a1');
      expect(list.first.activityType, ActivityType.run);
      await store.close();
    });

    test('upsert replaces an existing record', () async {
      final store = makeStore();
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
      final store = makeStore();
      final older = _record(id: 'older', endedAt: DateTime.utc(2026, 6, 1));
      final newer = _record(id: 'newer', endedAt: DateTime.utc(2026, 6, 2));
      await store.upsert(older);
      await store.upsert(newer);

      final list = await store.list();
      expect(list.map((r) => r.id).toList(), ['newer', 'older']);
      await store.close();
    });

    test('get returns null for unknown id', () async {
      final store = makeStore();
      expect(await store.get('nonexistent'), isNull);
      await store.close();
    });

    test('get returns the correct record by id', () async {
      final store = makeStore();
      await store.upsert(_record(id: 'a'));
      await store.upsert(_record(id: 'b'));

      final result = await store.get('b');
      expect(result?.id, 'b');
      await store.close();
    });

    test('getByIds returns matching records and ignores missing ids', () async {
      final store = makeStore();
      await store.upsert(_record(id: 'a'));
      await store.upsert(_record(id: 'b'));
      await store.upsert(_record(id: 'c'));

      final results = await store.getByIds({'a', 'c', 'missing'});

      expect(results.map((record) => record.id).toSet(), {'a', 'c'});
      await store.close();
    });

    test('delete removes a record', () async {
      final store = makeStore();
      await store.upsert(_record(id: 'a1'));
      await store.delete('a1');

      expect(await store.list(), isEmpty);
      await store.close();
    });

    test('delete on unknown id does not throw', () async {
      final store = makeStore();
      await expectLater(store.delete('nonexistent'), completes);
      await store.close();
    });

    test('bindUnassignedToProfile claims only unassigned records', () async {
      final store = makeStore();
      await store.upsert(_record(id: 'guest-1'));
      await store.upsert(_record(id: 'guest-2'));
      await store.upsert(
        _record(id: 'bound').copyWith(
          connectionOrigin: 'https://existing.example',
          connectionProfileId: 'profile-existing',
        ),
      );

      final bound = await store.bindUnassignedToProfile(
        origin: 'https://active.example',
        profileId: 'profile-active',
        updatedAt: DateTime.utc(2026, 6, 3, 9),
      );

      expect(bound, 2);
      expect(
        (await store.get('guest-1'))?.connectionOrigin,
        'https://active.example',
      );
      expect(
        (await store.get('guest-2'))?.connectionProfileId,
        'profile-active',
      );
      // A record already bound to a connection is left untouched.
      expect(
        (await store.get('bound'))?.connectionOrigin,
        'https://existing.example',
      );
      await store.close();
    });

    test('upsert persists all nullable fields', () async {
      final store = makeStore();
      final now = DateTime.utc(2026, 6, 1, 12);
      final record = _record(id: 'r1').copyWith(
        uploadStatus: LocalActivityUploadStatus.uploaded,
        uploadedAt: now,
        connectionOrigin: 'https://example.test',
        connectionProfileId: 'profile-1',
      );
      await store.upsert(record);

      final retrieved = await store.get('r1');
      expect(retrieved?.uploadedAt, now);
      expect(retrieved?.connectionOrigin, 'https://example.test');
      expect(retrieved?.connectionProfileId, 'profile-1');
      await store.close();
    });

    test('null optional fields round-trip as null', () async {
      final store = makeStore();
      await store.upsert(_record(id: 'r2'));

      final retrieved = await store.get('r2');
      expect(retrieved?.uploadedAt, isNull);
      expect(retrieved?.averageSpeedMetersPerSecond, isNull);
      await store.close();
    });
  });

  group('SqfliteActivityStore – pagination', () {
    test('count returns 0 for empty store', () async {
      final store = makeStore();
      expect(await store.count(), 0);
      await store.close();
    });

    test('count returns total number of records', () async {
      final store = makeStore();
      await store.upsert(_record(id: 'p1', endedAt: DateTime.utc(2026, 6, 3)));
      await store.upsert(_record(id: 'p2', endedAt: DateTime.utc(2026, 6, 2)));
      await store.upsert(_record(id: 'p3', endedAt: DateTime.utc(2026, 6, 1)));
      expect(await store.count(), 3);
      await store.close();
    });

    test('listPage returns first page in newest-first order', () async {
      final store = makeStore();
      await store.upsert(_record(id: 'p1', endedAt: DateTime.utc(2026, 6, 3)));
      await store.upsert(_record(id: 'p2', endedAt: DateTime.utc(2026, 6, 2)));
      await store.upsert(_record(id: 'p3', endedAt: DateTime.utc(2026, 6, 1)));

      final page = await store.listPage(offset: 0, limit: 2);
      expect(page.map((r) => r.id).toList(), ['p1', 'p2']);
      await store.close();
    });

    test('listPage with offset returns remaining records', () async {
      final store = makeStore();
      await store.upsert(_record(id: 'p1', endedAt: DateTime.utc(2026, 6, 3)));
      await store.upsert(_record(id: 'p2', endedAt: DateTime.utc(2026, 6, 2)));
      await store.upsert(_record(id: 'p3', endedAt: DateTime.utc(2026, 6, 1)));

      final page = await store.listPage(offset: 2, limit: 2);
      expect(page.map((r) => r.id).toList(), ['p3']);
      await store.close();
    });

    test('listPage beyond last record returns empty list', () async {
      final store = makeStore();
      await store.upsert(_record(id: 'p1', endedAt: DateTime.utc(2026, 6, 3)));
      await store.upsert(_record(id: 'p2', endedAt: DateTime.utc(2026, 6, 2)));
      await store.upsert(_record(id: 'p3', endedAt: DateTime.utc(2026, 6, 1)));

      final page = await store.listPage(offset: 5, limit: 2);
      expect(page, isEmpty);
      await store.close();
    });
  });

  group('SqfliteActivityStore – listByUploadStatus', () {
    test('returns matching records oldest-first', () async {
      final store = makeStore();
      await store.upsert(
        _record(
          id: 'older',
          endedAt: DateTime.utc(2026, 6, 1),
          uploadStatus: LocalActivityUploadStatus.failed,
        ),
      );
      await store.upsert(
        _record(
          id: 'newer',
          endedAt: DateTime.utc(2026, 6, 3),
          uploadStatus: LocalActivityUploadStatus.pending,
        ),
      );
      await store.upsert(
        _record(
          id: 'done',
          endedAt: DateTime.utc(2026, 6, 2),
          uploadStatus: LocalActivityUploadStatus.uploaded,
        ),
      );

      final result = await store.listByUploadStatus({
        LocalActivityUploadStatus.pending,
        LocalActivityUploadStatus.failed,
      });

      expect(result.map((r) => r.id).toList(), ['older', 'newer']);
      await store.close();
    });

    test('returns empty list for empty status set', () async {
      final store = makeStore();
      await store.upsert(
        _record(id: 'x', uploadStatus: LocalActivityUploadStatus.failed),
      );

      expect(await store.listByUploadStatus(const {}), isEmpty);
      await store.close();
    });
  });

  group('SqfliteActivityStore – schema migration', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('endurain_activity_db');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('creates the schema and persists data across reopen', () async {
      final dbPath = '${tempDir.path}${Platform.pathSeparator}activity.db';

      final first = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath,
      );
      await first.upsert(_record(id: 'persist-1'));
      await first.close();

      // Reopening the same on-disk database must NOT re-run onCreate or wipe
      // existing rows — the recorded schema version short-circuits migrations.
      final second = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath,
      );
      final list = await second.list();
      expect(list.map((r) => r.id).toList(), ['persist-1']);
      await second.close();
    });

    test('records the current schema version in schema_version', () async {
      final dbPath = '${tempDir.path}${Platform.pathSeparator}activity.db';
      final store = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath,
      );
      // Force the database to open by issuing a query.
      await store.list();

      final db = await databaseFactoryFfi.openDatabase(dbPath);
      final rows = await db.query('schema_version');
      expect(rows, hasLength(1));
      expect(rows.first['version'], 7);
      final columns = await db.rawQuery('PRAGMA table_info(local_activity)');
      expect(
        columns.map((column) => column['name']),
        isNot(contains('server_activity_id')),
      );
      await db.close();
      await store.close();
    });

    test('persists and restores the idempotency key', () async {
      final dbPath = '${tempDir.path}${Platform.pathSeparator}activity.db';
      final store = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath,
      );
      final record = _record(
        id: 'idem-1',
      ).copyWith(idempotencyKey: 'health_uuid');
      await store.upsert(record);
      await store.close();

      final reopened = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath,
      );
      final restored = await reopened.get('idem-1');
      expect(restored?.idempotencyKey, 'health_uuid');
      expect(restored?.effectiveIdempotencyKey, 'health_uuid');
      await reopened.close();
    });

    test('persists automatic retry eligibility', () async {
      final dbPath = '${tempDir.path}${Platform.pathSeparator}activity.db';
      final store = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath,
      );
      await store.upsert(
        _record(id: 'manual-only').copyWith(autoRetryEligible: false),
      );
      await store.close();

      final reopened = SqfliteActivityStore(
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath,
      );
      expect((await reopened.get('manual-only'))?.autoRetryEligible, isFalse);
      await reopened.close();
    });

    test(
      'upgrades a v1 database by adding the idempotency_key column',
      () async {
        final dbPath = '${tempDir.path}${Platform.pathSeparator}activity.db';
        // Simulate a database created by schema version 1 (no idempotency_key).
        final v1 = await databaseFactoryFfi.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                'CREATE TABLE schema_version (version INTEGER NOT NULL)',
              );
              await db.insert('schema_version', {'version': 1});
              await db.execute('''
              CREATE TABLE local_activity (
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
        await v1.close();

        final store = SqfliteActivityStore(
          databaseFactory: databaseFactoryFfi,
          databasePath: dbPath,
        );
        // Opening triggers onUpgrade; a write exercises the new column.
        await store.upsert(
          _record(id: 'upgraded').copyWith(idempotencyKey: 'health_x'),
        );
        final restored = await store.get('upgraded');
        expect(restored?.idempotencyKey, 'health_x');
        await store.close();
      },
    );
  });
}

LocalActivityRecord _record({
  required String id,
  DateTime? endedAt,
  LocalActivityUploadStatus uploadStatus = LocalActivityUploadStatus.pending,
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
    uploadStatus: uploadStatus,
    createdAt: ended,
    updatedAt: ended,
  );
}
