import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_share_service.dart';
import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
  group('LocalActivityHistoryController', () {
    late Directory tempDirectory;
    late LocalActivityRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_history_controller_',
      );
      repository = createTestLocalActivityRepository(tempDirectory);
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('loads empty state', () async {
      final controller = LocalActivityHistoryController(
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        shareService: FakeShareService(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
      expect(controller.records, isEmpty);
    });

    test('retries pending upload successfully', () async {
      final record = await _createRecord(repository, id: 'retry_success');
      final controller = LocalActivityHistoryController(
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        shareService: FakeShareService(),
      );
      addTearDown(controller.dispose);
      await controller.load();

      await controller.retryUpload(record.id);

      final updatedRecord = (await repository.list()).single;
      expect(updatedRecord.uploadStatus, LocalActivityUploadStatus.uploaded);
      expect(updatedRecord.uploadedAt, isNotNull);
      expect(updatedRecord.lastUploadErrorCode, isNull);
      expect(await repository.hasGpx(updatedRecord), isTrue);
    });

    test('marks retry failure safely', () async {
      final record = await _createRecord(repository, id: 'retry_failed');
      final controller = LocalActivityHistoryController(
        repository: repository,
        uploadService: _uploadServiceReturning(500),
        shareService: FakeShareService(),
      );
      addTearDown(controller.dispose);
      await controller.load();

      await expectLater(
        controller.retryUpload(record.id),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.activityUploadFailed,
          ),
        ),
      );

      final updatedRecord = (await repository.list()).single;
      expect(updatedRecord.uploadStatus, LocalActivityUploadStatus.failed);
      expect(
        updatedRecord.lastUploadErrorCode,
        AppErrorCode.activityUploadFailed,
      );
      expect(await repository.hasGpx(updatedRecord), isTrue);
    });

    test('deletes local record and refreshes list', () async {
      final record = await _createRecord(repository, id: 'delete_record');
      final controller = LocalActivityHistoryController(
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        shareService: FakeShareService(),
      );
      addTearDown(controller.dispose);
      await controller.load();

      await controller.delete(record.id);

      expect(controller.records, isEmpty);
      expect(await repository.list(), isEmpty);
    });
  });
}

Future<LocalActivityRecord> _createRecord(
  LocalActivityRepository repository, {
  required String id,
}) async {
  final fileName = await repository.writeGpx(id: id, gpx: '<gpx />');
  final record = LocalActivityRecord(
    id: id,
    activityType: ActivityType.run,
    startedAt: DateTime.utc(2026, 6, 2, 10),
    endedAt: DateTime.utc(2026, 6, 2, 10, 30),
    elapsedDurationSeconds: 1800,
    distanceMeters: 5000,
    averageSpeedMetersPerSecond: 2.7,
    pointCount: 40,
    gpxFileName: fileName,
    uploadStatus: LocalActivityUploadStatus.pending,
    createdAt: DateTime.utc(2026, 6, 2, 10, 31),
    updatedAt: DateTime.utc(2026, 6, 2, 10, 31),
  );
  await repository.upsert(record);
  return record;
}

ActivityUploadService _uploadServiceReturning(int statusCode) {
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    uploadFile: (_, _, _, {idempotencyKey}) async {
      return http.StreamedResponse(const Stream<List<int>>.empty(), statusCode);
    },
  );
}
