import 'dart:async';
import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/gpx_document_builder.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_preferences_store.dart';
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

  group('LocalActivityHistoryController GPX retention', () {
    late Directory tempDirectory;
    late LocalActivityRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_history_retention_',
      );
      repository = createTestLocalActivityRepository(tempDirectory);
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    LocalActivityHistoryController buildController(
      ActivityRetentionSettingsRepository? retention,
    ) {
      final controller = LocalActivityHistoryController(
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        shareService: FakeShareService(),
        retentionSettingsRepository: retention,
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test('is not configurable without a retention repository', () async {
      final controller = buildController(null);

      await controller.load();

      expect(controller.canConfigureGpxRetention, isFalse);
      expect(controller.retainUploadedGpx, isTrue);
    });

    test('load reads the stored preference', () async {
      final retention = _FakeRetentionSettings()..retainUploadedGpx = false;
      final controller = buildController(retention);

      await controller.load();

      expect(controller.canConfigureGpxRetention, isTrue);
      expect(controller.retainUploadedGpx, isFalse);
    });

    test('a failing preference read keeps the default and the list', () async {
      await _createRecord(repository, id: 'local-1');
      final controller = buildController(_ThrowingRetentionSettings());

      await controller.load();

      expect(controller.retainUploadedGpx, isTrue);
      expect(controller.records.map((record) => record.id), ['local-1']);
      expect(controller.error, isNull);
    });

    test('setRetainUploadedGpx persists the new value', () async {
      final retention = _FakeRetentionSettings();
      final controller = buildController(retention);
      await controller.load();

      await controller.setRetainUploadedGpx(false);

      expect(controller.retainUploadedGpx, isFalse);
      expect(retention.retainUploadedGpx, isFalse);
    });

    test('setRetainUploadedGpx reverts when the write fails', () async {
      final controller = buildController(_ThrowingRetentionSettings());
      await controller.load();

      await controller.setRetainUploadedGpx(false);

      // The switch must not keep showing a value that was never stored.
      expect(controller.retainUploadedGpx, isTrue);
    });

    test('a read that finishes after a save does not undo it', () async {
      final retention = _GatedRetentionSettings()..stored = true;
      final controller = buildController(retention);

      final load = controller.load();
      // The read is in flight with the old value when the user toggles.
      final save = controller.setRetainUploadedGpx(false);
      await pumpEventQueue();
      retention.writes.single.complete();
      await save;
      retention.reads.single.complete();
      await load;

      expect(controller.retainUploadedGpx, isFalse);
      expect(retention.stored, isFalse);
    });

    test('overlapping saves that both fail match what is stored', () async {
      final retention = _GatedRetentionSettings()..stored = true;
      final controller = buildController(retention);
      final load = controller.load();
      retention.reads.single.complete();
      await load;

      final first = controller.setRetainUploadedGpx(false);
      final second = controller.setRetainUploadedGpx(true);
      // Writes run one at a time, in order.
      await pumpEventQueue();
      expect(retention.writes, hasLength(1));
      retention.writes[0].completeError(StateError('write failed'));
      await pumpEventQueue();
      expect(retention.writes, hasLength(2));
      retention.writes[1].completeError(StateError('write failed'));
      await Future.wait([first, second]);

      expect(retention.stored, isTrue);
      expect(controller.retainUploadedGpx, isTrue);
    });

    test('a failed save after a successful one reverts to it', () async {
      final retention = _GatedRetentionSettings()..stored = true;
      final controller = buildController(retention);

      final first = controller.setRetainUploadedGpx(false);
      final second = controller.setRetainUploadedGpx(true);
      await pumpEventQueue();
      retention.writes[0].complete();
      await pumpEventQueue();
      retention.writes[1].completeError(StateError('write failed'));
      await Future.wait([first, second]);

      expect(retention.stored, isFalse);
      expect(controller.retainUploadedGpx, isFalse);
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

class _FakeRetentionSettings extends ActivityRetentionSettingsRepository {
  _FakeRetentionSettings() : super(preferences: FakePreferencesStore());

  bool retainUploadedGpx = true;

  @override
  Future<bool> isRetainUploadedGpxEnabled() async => retainUploadedGpx;

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {
    retainUploadedGpx = enabled;
  }
}

class _ThrowingRetentionSettings extends ActivityRetentionSettingsRepository {
  _ThrowingRetentionSettings() : super(preferences: FakePreferencesStore());

  @override
  Future<bool> isRetainUploadedGpxEnabled() async {
    throw const AppException(AppErrorCode.secureStorageReadFailed);
  }

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {
    throw const AppException(AppErrorCode.secureStorageWriteFailed);
  }
}

/// Retention settings whose reads and writes finish only when a test
/// completes them, to reproduce overlapping loads and saves.
class _GatedRetentionSettings extends ActivityRetentionSettingsRepository {
  _GatedRetentionSettings() : super(preferences: FakePreferencesStore());

  bool stored = true;
  final List<Completer<void>> reads = [];
  final List<Completer<void>> writes = [];

  @override
  Future<bool> isRetainUploadedGpxEnabled() async {
    final value = stored;
    final gate = Completer<void>();
    reads.add(gate);
    await gate.future;
    return value;
  }

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {
    final gate = Completer<void>();
    writes.add(gate);
    await gate.future;
    stored = enabled;
  }
}
