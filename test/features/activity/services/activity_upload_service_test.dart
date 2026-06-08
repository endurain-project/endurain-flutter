import 'dart:io';

import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ActivityUploadService', () {
    test('default Endurain config targets the upload contract', () {
      const config = ActivityUploadConfig.endurain();

      expect(config.endpoint, ApiConstants.activityUploadEndpoint);
      expect(config.fieldName, ApiConstants.activityUploadFieldName);
      expect(config.isConfigured, isTrue);
    });

    test('fromEndpoints uses the config apiBasePath', () {
      const v2Config = AppConfig(apiBasePath: '/api/v2');
      final config = ActivityUploadConfig.fromEndpoints(
        const ApiEndpoints(v2Config),
      );

      expect(config.endpoint, '/api/v2/activities/create/upload');
      expect(config.fieldName, ApiConstants.activityUploadFieldName);
      expect(config.isConfigured, isTrue);
    });

    test('uploads GPX with configured endpoint and field', () async {
      String? endpoint;
      String? filePath;
      String? fieldName;
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/api/v1/activities/import/gpx',
          fieldName: 'file',
        ),
        uploadFile: (uploadEndpoint, uploadPath, uploadFieldName) async {
          endpoint = uploadEndpoint;
          filePath = uploadPath;
          fieldName = uploadFieldName;
          return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
        },
      );

      await service.uploadGpx(
        const ActivityUploadRequest(
          filePath: '/tmp/activity.gpx',
          activityType: ActivityType.run,
        ),
      );

      expect(endpoint, '/api/v1/activities/import/gpx');
      expect(filePath, '/tmp/activity.gpx');
      expect(fieldName, 'file');
    });

    test('blocks upload when the server contract is missing', () async {
      final service = ActivityUploadService();

      await expectLater(
        service.uploadGpx(
          const ActivityUploadRequest(
            filePath: '/tmp/activity.gpx',
            activityType: ActivityType.ride,
          ),
        ),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.activityUploadNotConfigured,
          ),
        ),
      );
    });

    test('maps auth failures to session expired', () async {
      final service = _serviceReturningStatus(401);

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.sessionExpired,
          ),
        ),
      );
    });

    test(
      'maps validation failures without raw server response details',
      () async {
        final service = _serviceReturningStatus(422);

        await expectLater(
          service.uploadGpx(_request()),
          throwsA(
            isA<AppException>()
                .having(
                  (exception) => exception.code,
                  'code',
                  AppErrorCode.activityUploadFailed,
                )
                .having(
                  (exception) => exception.details,
                  'details',
                  'HTTP 422',
                ),
          ),
        );
      },
    );

    test('maps network failures to upload failed', () async {
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/upload',
          fieldName: 'file',
        ),
        uploadFile: (_, _, _) async => throw const FormatException('offline'),
      );

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.activityUploadFailed,
          ),
        ),
      );
    });
  });

  group('ActivityUploadService.performUploadAttempt', () {
    late Directory tempDir;
    late LocalActivityRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('endurain_upload_svc_');
      repository = LocalActivityRepository(
        supportDirectoryProvider: () async => tempDir,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test(
      'marks record uploaded and retains GPX by default on success',
      () async {
        final record = await _createRecord(repository, id: 'svc_success');
        final now = DateTime.utc(2026, 6, 8, 10, 0);
        final service = _serviceReturningStatus(201);

        final result = await service.performUploadAttempt(
          record: record,
          repository: repository,
          now: () => now,
        );

        expect(result.uploadStatus, LocalActivityUploadStatus.uploaded);
        expect(result.uploadedAt, now);
        expect(result.lastUploadErrorCode, isNull);
        expect(await repository.hasGpx(result), isTrue);
      },
    );

    test('marks record failed and rethrows on upload error', () async {
      final record = await _createRecord(repository, id: 'svc_fail');
      final service = _serviceReturningStatus(500);

      await expectLater(
        service.performUploadAttempt(record: record, repository: repository),
        throwsA(isA<AppException>()),
      );

      final persisted = await repository.get(record.id);
      expect(persisted!.uploadStatus, LocalActivityUploadStatus.failed);
      expect(persisted.lastUploadErrorCode, AppErrorCode.activityUploadFailed);
    });

    test(
      'throws activityUploadNotConfigured when service is not configured',
      () async {
        final record = await _createRecord(
          repository,
          id: 'svc_not_configured',
        );
        final service = ActivityUploadService(); // no config

        await expectLater(
          service.performUploadAttempt(record: record, repository: repository),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.activityUploadNotConfigured,
            ),
          ),
        );

        final persisted = await repository.get(record.id);
        expect(persisted!.uploadStatus, LocalActivityUploadStatus.failed);
      },
    );

    test('5xx is retried and succeeds on second attempt', () async {
      final record = await _createRecord(repository, id: 'svc_retry_5xx');
      final service = _serviceWithResponses([500, 201]);

      final result = await service.performUploadAttempt(
        record: record,
        repository: repository,
      );

      expect(result.uploadStatus, LocalActivityUploadStatus.uploaded);
    });

    test('5xx is not retried when maxAttempts is 1 (default)', () async {
      final record = await _createRecord(repository, id: 'svc_no_retry');
      final service = _serviceReturningStatus(500); // default: maxAttempts=1

      await expectLater(
        service.performUploadAttempt(record: record, repository: repository),
        throwsA(isA<AppException>()),
      );

      final persisted = await repository.get(record.id);
      expect(persisted!.uploadStatus, LocalActivityUploadStatus.failed);
    });

    test('4xx is not retried even when maxAttempts > 1', () async {
      final record = await _createRecord(repository, id: 'svc_no_retry_4xx');
      // maxAttempts=3 but the 422 should not be retried
      final service = _serviceWithResponses([422, 201, 201]);

      await expectLater(
        service.performUploadAttempt(record: record, repository: repository),
        throwsA(
          isA<AppException>().having((e) => e.details, 'details', 'HTTP 422'),
        ),
      );

      final persisted = await repository.get(record.id);
      expect(persisted!.uploadStatus, LocalActivityUploadStatus.failed);
    });

    test('401 is not retried', () async {
      final record = await _createRecord(repository, id: 'svc_no_retry_401');
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/upload',
          fieldName: 'file',
        ),
        retryPolicy: ActivityUploadRetryPolicy(
          maxAttempts: 3,
          delay: (_) async {},
        ),
        uploadFile: (_, _, _) async {
          return http.StreamedResponse(const Stream<List<int>>.empty(), 401);
        },
      );

      await expectLater(
        service.performUploadAttempt(record: record, repository: repository),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.sessionExpired,
          ),
        ),
      );

      final persisted = await repository.get(record.id);
      expect(persisted!.uploadStatus, LocalActivityUploadStatus.failed);
    });
  });
}

ActivityUploadService _serviceReturningStatus(int statusCode) {
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    uploadFile: (_, _, _) async {
      return http.StreamedResponse(const Stream<List<int>>.empty(), statusCode);
    },
  );
}

ActivityUploadService _serviceWithResponses(List<int> statusCodes) {
  var callCount = 0;
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    retryPolicy: ActivityUploadRetryPolicy(
      maxAttempts: statusCodes.length,
      delay: (_) async {},
    ),
    uploadFile: (_, _, _) async {
      final code = statusCodes[callCount++];
      return http.StreamedResponse(const Stream<List<int>>.empty(), code);
    },
  );
}

ActivityUploadRequest _request() {
  return const ActivityUploadRequest(
    filePath: '/tmp/activity.gpx',
    activityType: ActivityType.run,
  );
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
    pointCount: 40,
    gpxFileName: fileName,
    uploadStatus: LocalActivityUploadStatus.pending,
    createdAt: DateTime.utc(2026, 6, 2, 10, 31),
    updatedAt: DateTime.utc(2026, 6, 2, 10, 31),
  );
  await repository.upsert(record);
  return record;
}
