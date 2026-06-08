import 'dart:io';

import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/json_manifest_activity_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonManifestActivityStore – pagination', () {
    late Directory tempDir;
    late JsonManifestActivityStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'endurain_json_manifest_',
      );
      store = JsonManifestActivityStore(
        supportDirectoryProvider: () async => tempDir,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<void> seedThreeRecords() async {
      await store.upsert(_record(id: 'p1', endedAt: DateTime.utc(2026, 6, 3)));
      await store.upsert(_record(id: 'p2', endedAt: DateTime.utc(2026, 6, 2)));
      await store.upsert(_record(id: 'p3', endedAt: DateTime.utc(2026, 6, 1)));
    }

    test('count returns 0 for empty store', () async {
      expect(await store.count(), 0);
    });

    test('count returns total number of records', () async {
      await seedThreeRecords();
      expect(await store.count(), 3);
    });

    test('listPage returns first page in newest-first order', () async {
      await seedThreeRecords();

      final page = await store.listPage(offset: 0, limit: 2);
      expect(page.map((r) => r.id).toList(), ['p1', 'p2']);
    });

    test('listPage with offset returns remaining records', () async {
      await seedThreeRecords();

      final page = await store.listPage(offset: 2, limit: 2);
      expect(page.map((r) => r.id).toList(), ['p3']);
    });

    test('listPage beyond last record returns empty list', () async {
      await seedThreeRecords();

      final page = await store.listPage(offset: 5, limit: 2);
      expect(page, isEmpty);
    });

    test('listByUploadStatus returns matching records oldest-first', () async {
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
    });
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
