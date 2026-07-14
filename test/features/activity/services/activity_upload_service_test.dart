import 'dart:async';
import 'dart:io';

import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
  group('ActivityUploadService', () {
    test('default Endurain config targets the upload contract', () {
      final config = ActivityUploadConfig.fromEndpoints(ApiEndpoints.defaults);

      expect(config.endpoint, ApiEndpoints.defaults.activityUploadEndpoint);
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
        uploadFile:
            (
              uploadEndpoint,
              uploadPath,
              uploadFieldName, {
              idempotencyKey,
            }) async {
              endpoint = uploadEndpoint;
              filePath = uploadPath;
              fieldName = uploadFieldName;
              return http.StreamedResponse(
                const Stream<List<int>>.empty(),
                201,
              );
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

    test('forwards the idempotency key to the uploader', () async {
      String? capturedKey;
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/upload',
          fieldName: 'file',
        ),
        uploadFile: (_, _, _, {idempotencyKey}) async {
          capturedKey = idempotencyKey;
          return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
        },
      );

      await service.uploadGpx(
        const ActivityUploadRequest(
          filePath: '/tmp/activity.gpx',
          activityType: ActivityType.run,
          idempotencyKey: 'activity-123',
        ),
      );

      expect(capturedKey, 'activity-123');
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
        uploadFile: (_, _, _, {idempotencyKey}) async =>
            throw const FormatException('offline'),
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
      repository = createTestLocalActivityRepository(tempDir);
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

    test('originless guest record never reaches the uploader', () async {
      final record = await _createRecord(
        repository,
        id: 'svc_guest',
        connectionOrigin: null,
      );
      var uploadCalls = 0;
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/upload',
          fieldName: 'file',
        ),
        uploadFile: (_, _, _, {idempotencyKey}) async {
          uploadCalls++;
          return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
        },
      );

      await expectLater(
        service.performUploadAttempt(record: record, repository: repository),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
      expect(uploadCalls, 0);
    });

    test('concurrent attempts for one record share one upload', () async {
      final record = await _createRecord(repository, id: 'svc_single_flight');
      final started = Completer<void>();
      final finish = Completer<void>();
      var uploadCalls = 0;
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/upload',
          fieldName: 'file',
        ),
        uploadFile: (_, _, _, {idempotencyKey}) async {
          uploadCalls++;
          if (!started.isCompleted) {
            started.complete();
          }
          await finish.future;
          return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
        },
      );

      final first = service.performUploadAttempt(
        record: record,
        repository: repository,
      );
      await started.future;
      final second = service.performUploadAttempt(
        record: record,
        repository: repository,
      );
      finish.complete();

      final results = await Future.wait([first, second]);
      expect(uploadCalls, 1);
      expect(
        results.map((record) => record.uploadStatus),
        everyElement(LocalActivityUploadStatus.uploaded),
      );
    });

    test(
      'does not recreate a record deleted while its upload is in flight',
      () async {
        final record = await _createRecord(repository, id: 'svc_deleted');
        final uploadStarted = Completer<void>();
        final releaseUpload = Completer<void>();
        final service = ActivityUploadService(
          config: const ActivityUploadConfig(
            endpoint: '/upload',
            fieldName: 'file',
          ),
          uploadFile: (_, _, _, {idempotencyKey}) async {
            uploadStarted.complete();
            await releaseUpload.future;
            return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
          },
        );

        final attempt = service.performUploadAttempt(
          record: record,
          repository: repository,
        );
        await uploadStarted.future;
        await repository.delete(record.id);
        releaseUpload.complete();

        await expectLater(
          attempt,
          throwsA(
            isA<AppException>().having(
              (error) => error.code,
              'code',
              AppErrorCode.activityLocalActivityNotFound,
            ),
          ),
        );
        expect(await repository.get(record.id), isNull);
      },
    );

    test('stale pending snapshot does not downgrade uploaded state', () async {
      final stale = await _createRecord(repository, id: 'svc_stale');
      final uploaded = stale.copyWith(
        uploadStatus: LocalActivityUploadStatus.uploaded,
        uploadedAt: DateTime.utc(2026, 6, 8),
      );
      await repository.upsert(uploaded);
      await repository.deleteGpx(uploaded);
      var uploadCalls = 0;
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/upload',
          fieldName: 'file',
        ),
        uploadFile: (_, _, _, {idempotencyKey}) async {
          uploadCalls++;
          return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
        },
      );

      final result = await service.performUploadAttempt(
        record: stale,
        repository: repository,
      );

      expect(result.uploadStatus, LocalActivityUploadStatus.uploaded);
      expect(uploadCalls, 0);
      expect(
        (await repository.get(stale.id))?.uploadStatus,
        LocalActivityUploadStatus.uploaded,
      );
    });

    test('keeps record uploaded when post-upload GPX cleanup fails', () async {
      final cleanupThrowingRepository = _DeleteGpxThrowingRepository(tempDir);
      final record = await _createRecord(
        cleanupThrowingRepository,
        id: 'svc_cleanup_failed',
      );
      final service = _serviceReturningStatus(201);

      final result = await service.performUploadAttempt(
        record: record,
        repository: cleanupThrowingRepository,
        retentionRepository: const _FakeRetentionSettings(enabled: false),
      );

      expect(result.uploadStatus, LocalActivityUploadStatus.uploaded);
      expect(result.lastUploadErrorCode, AppErrorCode.activityGpxCleanupFailed);
      expect(await cleanupThrowingRepository.hasGpx(result), isTrue);

      final persisted = await cleanupThrowingRepository.get(record.id);
      expect(persisted!.uploadStatus, LocalActivityUploadStatus.uploaded);
      expect(
        persisted.lastUploadErrorCode,
        AppErrorCode.activityGpxCleanupFailed,
      );
      expect(persisted.gpxCleanupPending, isTrue);
    });

    test('retries uploaded GPX cleanup without uploading again', () async {
      final record = await _createRecord(repository, id: 'svc_cleanup_retry');
      var uploads = 0;
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/upload',
          fieldName: 'file',
        ),
        uploadFile: (_, _, _, {idempotencyKey}) async {
          uploads++;
          return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
        },
      );
      const retained = _FakeRetentionSettings(enabled: true);
      final first = await service.performUploadAttempt(
        record: record,
        repository: repository,
        retentionRepository: retained,
      );
      await repository.upsert(first.copyWith(gpxCleanupPending: true));

      final result = await service.performUploadAttempt(
        record: first,
        repository: repository,
        retentionRepository: const _FakeRetentionSettings(enabled: false),
      );

      expect(uploads, 1);
      expect(result.gpxCleanupPending, isFalse);
      expect(await repository.hasGpx(result), isFalse);
    });

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
      expect(persisted.autoRetryEligible, isTrue);
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
        expect(persisted.autoRetryEligible, isFalse);
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

    test('uses the record id as the idempotency key', () async {
      final record = await _createRecord(repository, id: 'svc_idem');
      final keys = <String?>[];
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/upload',
          fieldName: 'file',
        ),
        uploadFile: (_, _, _, {idempotencyKey}) async {
          keys.add(idempotencyKey);
          return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
        },
      );

      await service.performUploadAttempt(
        record: record,
        repository: repository,
      );

      expect(keys, ['svc_idem']);
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
      expect(persisted.autoRetryEligible, isTrue);
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
      expect(persisted.autoRetryEligible, isFalse);
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
        uploadFile: (_, _, _, {idempotencyKey}) async {
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
      expect(persisted.autoRetryEligible, isFalse);
    });

    test('unexpected non-IO error fails fast without retrying', () async {
      final throwingRepo = _ReadPathThrowingRepository(tempDir);
      final record = await _createRecord(throwingRepo, id: 'svc_bug');
      var delayCalls = 0;
      final service = ActivityUploadService(
        config: const ActivityUploadConfig(
          endpoint: '/upload',
          fieldName: 'file',
        ),
        retryPolicy: ActivityUploadRetryPolicy(
          maxAttempts: 3,
          delay: (_) async => delayCalls++,
        ),
        uploadFile: (_, _, _, {idempotencyKey}) async {
          return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
        },
      );

      await expectLater(
        service.performUploadAttempt(record: record, repository: throwingRepo),
        throwsA(isA<StateError>()),
      );

      // A programming bug (StateError) is not a transient I/O failure, so it
      // must not consume the retry budget.
      expect(delayCalls, 0);
      final persisted = await throwingRepo.get(record.id);
      expect(persisted!.uploadStatus, LocalActivityUploadStatus.failed);
    });
  });
}

class _ReadPathThrowingRepository extends LocalActivityRepository {
  _ReadPathThrowingRepository(Directory dir)
    : super(
        supportDirectoryProvider: () async => dir,
        store: createTestActivityStore(dir),
      );

  @override
  Future<String> readGpxFilePath(LocalActivityRecord record) {
    throw StateError('unexpected bug');
  }
}

class _DeleteGpxThrowingRepository extends LocalActivityRepository {
  _DeleteGpxThrowingRepository(Directory dir)
    : super(
        supportDirectoryProvider: () async => dir,
        store: createTestActivityStore(dir),
      );

  @override
  Future<void> deleteGpx(LocalActivityRecord record) {
    throw const AppException(AppErrorCode.activityLocalDeleteFailed);
  }
}

class _FakeRetentionSettings implements ActivityRetentionSettingsRepository {
  const _FakeRetentionSettings({required this.enabled});

  final bool enabled;

  @override
  Future<bool> isRetainUploadedGpxEnabled() async => enabled;

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {}
}

ActivityUploadService _serviceReturningStatus(int statusCode) {
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    uploadFile: (_, _, _, {idempotencyKey}) async {
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
    uploadFile: (_, _, _, {idempotencyKey}) async {
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
  String? connectionOrigin = 'https://example.test',
  String? connectionProfileId = 'profile-1',
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
    connectionOrigin: connectionOrigin,
    connectionProfileId: connectionProfileId,
  );
  await repository.upsert(record);
  return record;
}
