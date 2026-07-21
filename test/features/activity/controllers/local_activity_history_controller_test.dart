import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/gpx_document_builder.dart';
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

    test('loadRoute parses the stored GPX into a route', () async {
      final gpx = buildGpxDocument(
        name: 'run',
        type: 'run',
        segments: [
          [
            GpxTrackPoint(
              latitude: 41.1,
              longitude: -8.6,
              time: DateTime.utc(2026),
            ),
            GpxTrackPoint(
              latitude: 41.2,
              longitude: -8.5,
              time: DateTime.utc(2026, 1, 1, 0, 1),
            ),
          ],
        ],
      );
      final fileName = await repository.writeGpx(id: 'route_1', gpx: gpx);
      final record = _recordWithGpx(id: 'route_1', gpxFileName: fileName);
      await repository.upsert(record);
      final controller = LocalActivityHistoryController(
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        shareService: FakeShareService(),
      );
      addTearDown(controller.dispose);

      final route = await controller.loadRoute(record);

      expect(route, isNotNull);
      expect(route!.points, hasLength(2));
    });

    test('loadRoute returns null when the GPX has no track points', () async {
      final record = await _createRecord(repository, id: 'empty_route');
      final controller = LocalActivityHistoryController(
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        shareService: FakeShareService(),
      );
      addTearDown(controller.dispose);

      expect(await controller.loadRoute(record), isNull);
    });

    test('loadRoute returns null when the GPX file is missing', () async {
      final record = _recordWithGpx(id: 'ghost', gpxFileName: 'ghost.gpx');
      await repository.upsert(record);
      final controller = LocalActivityHistoryController(
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        shareService: FakeShareService(),
      );
      addTearDown(controller.dispose);

      expect(await controller.loadRoute(record), isNull);
    });

    test(
      'loads an activity by id independently of history pagination',
      () async {
        final target = await _createRecord(repository, id: 'target');
        for (var index = 0; index < 25; index++) {
          await _createRecord(repository, id: 'newer_$index');
        }
        final controller = LocalActivityHistoryController(
          repository: repository,
          uploadService: _uploadServiceReturning(201),
          shareService: FakeShareService(),
        );
        addTearDown(controller.dispose);

        await controller.loadRecord(target.id);

        expect(controller.records.map((record) => record.id), [target.id]);
        expect(controller.hasMore, isFalse);
      },
    );

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

    test(
      'retry updates an older loaded page without dropping newer rows',
      () async {
        for (var index = 0; index < 21; index++) {
          await _createRecord(repository, id: 'record_$index');
        }
        final controller = LocalActivityHistoryController(
          repository: repository,
          uploadService: _uploadServiceReturning(201),
          shareService: FakeShareService(),
        );
        addTearDown(controller.dispose);
        await controller.load();
        await controller.loadMore();
        final idsBefore = controller.records
            .map((record) => record.id)
            .toList();
        final oldestId = idsBefore.last;

        await controller.retryUpload(oldestId);

        expect(controller.records.map((record) => record.id), idsBefore);
        expect(
          controller.recordById(oldestId)?.uploadStatus,
          LocalActivityUploadStatus.uploaded,
        );
      },
    );

    test('deletes local record and refreshes list', () async {
      final record = await _createRecord(repository, id: 'delete_record');
      final removedProvenanceIds = <String>[];
      final controller = LocalActivityHistoryController(
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        shareService: FakeShareService(),
        removeImportProvenance: (id) async {
          removedProvenanceIds.add(id);
        },
      );
      addTearDown(controller.dispose);
      await controller.load();

      await controller.delete(record.id);

      expect(controller.records, isEmpty);
      expect(await repository.list(), isEmpty);
      expect(removedProvenanceIds, ['delete_record']);
    });

    group('exportGpx', () {
      test('shares GPX path with subject', () async {
        final record = await _createRecord(repository, id: 'export_ok');
        final shareService = FakeShareService();
        final controller = LocalActivityHistoryController(
          repository: repository,
          uploadService: _uploadServiceReturning(201),
          shareService: shareService,
        );
        addTearDown(controller.dispose);

        await controller.exportGpx(record.id, subject: 'My GPX');

        expect(shareService.calls, hasLength(1));
        expect(shareService.calls.single.subject, 'My GPX');
        expect(shareService.calls.single.paths, hasLength(1));
        expect(shareService.calls.single.paths.single, endsWith('.gpx'));
      });

      test('throws activityLocalActivityNotFound for unknown id', () async {
        final shareService = FakeShareService();
        final controller = LocalActivityHistoryController(
          repository: repository,
          uploadService: _uploadServiceReturning(201),
          shareService: shareService,
        );
        addTearDown(controller.dispose);

        await expectLater(
          controller.exportGpx('non-existent'),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.activityLocalActivityNotFound,
            ),
          ),
        );
        expect(shareService.calls, isEmpty);
      });

      test('rethrows activityLocalGpxMissing when GPX file absent', () async {
        // Create record without a GPX file on disk (gpxFileName points to
        // a nonexistent file).
        final record = LocalActivityRecord(
          id: 'no_gpx',
          activityType: ActivityType.run,
          startedAt: DateTime.utc(2026, 6, 2, 10),
          endedAt: DateTime.utc(2026, 6, 2, 10, 30),
          elapsedDurationSeconds: 1800,
          distanceMeters: 5000,
          averageSpeedMetersPerSecond: 2.7,
          pointCount: 0,
          gpxFileName: 'missing.gpx',
          uploadStatus: LocalActivityUploadStatus.pending,
          createdAt: DateTime.utc(2026, 6, 2, 10, 31),
          updatedAt: DateTime.utc(2026, 6, 2, 10, 31),
        );
        await repository.upsert(record);

        final shareService = FakeShareService();
        final controller = LocalActivityHistoryController(
          repository: repository,
          uploadService: _uploadServiceReturning(201),
          shareService: shareService,
        );
        addTearDown(controller.dispose);

        await expectLater(
          controller.exportGpx(record.id),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.activityLocalGpxMissing,
            ),
          ),
        );
        expect(shareService.calls, isEmpty);
      });
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
    connectionOrigin: 'https://example.test',
    connectionProfileId: 'profile-1',
  );
  await repository.upsert(record);
  return record;
}

LocalActivityRecord _recordWithGpx({
  required String id,
  required String gpxFileName,
}) {
  return LocalActivityRecord(
    id: id,
    activityType: ActivityType.run,
    startedAt: DateTime.utc(2026, 6, 2, 10),
    endedAt: DateTime.utc(2026, 6, 2, 10, 30),
    elapsedDurationSeconds: 1800,
    distanceMeters: 5000,
    pointCount: 2,
    gpxFileName: gpxFileName,
    uploadStatus: LocalActivityUploadStatus.pending,
    createdAt: DateTime.utc(2026, 6, 2, 10, 31),
    updatedAt: DateTime.utc(2026, 6, 2, 10, 31),
  );
}

ActivityUploadService _uploadServiceReturning(int statusCode) {
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    uploadFile:
        (_, _, _, {idempotencyKey, expectedOrigin, expectedProfileId}) async {
          return http.StreamedResponse(
            const Stream<List<int>>.empty(),
            statusCode,
          );
        },
  );
}
