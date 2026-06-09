import 'dart:io';

import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
  group('LocalActivityRepository', () {
    late Directory tempDirectory;
    late LocalActivityRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_activity_repo_',
      );
      repository = createTestLocalActivityRepository(tempDirectory);
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('returns an empty list when the store is empty', () async {
      expect(await repository.list(), isEmpty);
    });

    test('upserts records and sorts newest endedAt first', () async {
      final older = _record(id: 'older', endedAt: DateTime.utc(2026, 6, 1));
      final newer = _record(id: 'newer', endedAt: DateTime.utc(2026, 6, 2));

      await repository.upsert(older);
      await repository.upsert(newer);

      final records = await repository.list();
      expect(records.map((record) => record.id), ['newer', 'older']);

      await repository.upsert(
        older.copyWith(uploadStatus: LocalActivityUploadStatus.uploaded),
      );

      final updatedOlder = await repository.get('older');
      expect(updatedOlder?.uploadStatus, LocalActivityUploadStatus.uploaded);
    });

    test('writes reads and deletes retained GPX with metadata', () async {
      final fileName = await repository.writeGpx(
        id: 'activity_1',
        gpx: '<gpx />',
      );
      final record = _record(id: 'activity_1', gpxFileName: fileName);
      await repository.upsert(record);

      expect(await repository.hasGpx(record), isTrue);
      expect(
        File(await repository.readGpxFilePath(record)).existsSync(),
        isTrue,
      );

      await repository.delete(record.id);

      expect(await repository.list(), isEmpty);
      expect(await repository.hasGpx(record), isFalse);
    });
  });
}

LocalActivityRecord _record({
  required String id,
  DateTime? endedAt,
  String? gpxFileName,
}) {
  final ended = endedAt ?? DateTime.utc(2026, 6, 2, 10);
  return LocalActivityRecord(
    id: id,
    activityType: ActivityType.run,
    startedAt: ended.subtract(const Duration(minutes: 5)),
    endedAt: ended,
    elapsedDurationSeconds: 300,
    distanceMeters: 1200,
    averageSpeedMetersPerSecond: 4,
    pointCount: 8,
    gpxFileName: gpxFileName ?? '$id.gpx',
    uploadStatus: LocalActivityUploadStatus.pending,
    createdAt: ended,
    updatedAt: ended,
  );
}
