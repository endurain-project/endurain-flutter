import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'dart:async';
import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_upload_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/active_activity_store.dart';
import 'package:endurain/features/activity/repositories/file_active_activity_store.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_gpx_builder.dart';
import 'package:endurain/features/activity/services/activity_recording_service.dart';
import 'package:endurain/features/activity/services/activity_storage_paths.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/services/geolocator_activity_location_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/in_memory_active_activity_store.dart';
import '../../../helpers/recording_location_platform_adapter.dart';
import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
  group('ActivityRecordingController', () {
    test('starts recording with selected type', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = _recordingService(adapter: adapter);
      final controller = ActivityRecordingController(recordingService: service);
      addTearDown(controller.dispose);

      await controller.start(ActivityType.ride);
      await pumpEventQueue();

      expect(controller.selectedActivityType, ActivityType.ride);
      expect(controller.state.status, ActivityRecordingStatus.recording);
      expect(controller.state.activityType, ActivityType.ride);
    });

    group('active recording recovery', () {
      test('returns false when no active session exists', () async {
        final store = InMemoryActiveActivityStore();
        final controller = _controllerWithActiveStore(store);
        addTearDown(controller.dispose);

        final recovered = await controller.recoverActiveRecording();

        expect(recovered, isFalse);
        expect(controller.state.status, ActivityRecordingStatus.idle);
        expect(controller.selectedActivityType, ActivityType.run);
      });

      test('recovers a paused session and selected activity type', () async {
        final store = InMemoryActiveActivityStore();
        store.session = _activeSession(ActiveActivityStatus.paused);
        await store.appendPoints([
          _recordedPoint(segmentIndex: 0, latitude: 41.1),
          _recordedPoint(segmentIndex: 1, latitude: 41.2),
        ]);
        final controller = _controllerWithActiveStore(store);
        addTearDown(controller.dispose);

        final recovered = await controller.recoverActiveRecording();

        expect(recovered, isTrue);
        expect(controller.state.status, ActivityRecordingStatus.paused);
        expect(controller.state.activityType, ActivityType.ride);
        expect(controller.selectedActivityType, ActivityType.ride);
        expect(controller.state.points, hasLength(2));
        expect(controller.state.segments, hasLength(2));
      });

      test('recovers a recording session as paused', () async {
        final store = InMemoryActiveActivityStore();
        store.session = _activeSession(ActiveActivityStatus.recording);
        await store.appendPoints([
          _recordedPoint(segmentIndex: 0, latitude: 41.1),
        ]);
        final controller = _controllerWithActiveStore(store);
        addTearDown(controller.dispose);

        final recovered = await controller.recoverActiveRecording();

        expect(recovered, isTrue);
        expect(controller.state.status, ActivityRecordingStatus.paused);
        expect(controller.state.activityType, ActivityType.ride);
      });

      test('clears and returns false for an empty-point session', () async {
        final store = InMemoryActiveActivityStore();
        store.session = _activeSession(ActiveActivityStatus.paused);
        final controller = _controllerWithActiveStore(store);
        addTearDown(controller.dispose);

        final recovered = await controller.recoverActiveRecording();

        expect(recovered, isFalse);
        expect(controller.state.status, ActivityRecordingStatus.idle);
        expect(store.session, isNull);
      });

      test('returns false for malformed active session metadata', () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'endurain_controller_recover_malformed_',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
        final activeDirectory = Directory(
          '${tempDirectory.path}${Platform.pathSeparator}'
          '$activityStorageRootDir'
          '${Platform.pathSeparator}'
          '${FileActiveActivityStore.activeDirectoryName}',
        )..createSync(recursive: true);
        File(
          '${activeDirectory.path}${Platform.pathSeparator}'
          '${FileActiveActivityStore.sessionFileName}',
        ).writeAsStringSync('{ not valid json');
        final store = FileActiveActivityStore(
          supportDirectoryProvider: () async => tempDirectory,
        );
        final controller = _controllerWithActiveStore(store);
        addTearDown(controller.dispose);

        final recovered = await controller.recoverActiveRecording();

        expect(recovered, isFalse);
        expect(controller.state.status, ActivityRecordingStatus.idle);
      });
    });

    test('ignores type changes while active', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = _recordingService(adapter: adapter);
      final controller = ActivityRecordingController(recordingService: service);
      addTearDown(controller.dispose);

      await controller.start(ActivityType.run);
      await pumpEventQueue();
      controller.selectActivityType(ActivityType.hike);

      expect(controller.selectedActivityType, ActivityType.run);
    });

    test(
      'generates GPX and retained local record when recording completes',
      () async {
        final adapter = RecordingLocationPlatformAdapter();
        final tempDirectory = await Directory.systemTemp.createTemp(
          'endurain_local_complete_',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
        final repository = _repositoryFor(tempDirectory);
        final service = _recordingService(adapter: adapter);
        final controller = ActivityRecordingController(
          recordingService: service,
          localActivityRepository: repository,
          localActivityIdProvider: () => 'local_complete',
        );
        addTearDown(controller.dispose);

        await controller.start(ActivityType.run);
        adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
        await pumpEventQueue();
        await controller.stop();
        await controller.uploadCompletedGpx();

        final records = await repository.list();
        expect(controller.state.status, ActivityRecordingStatus.completed);
        expect(controller.completedGpx, contains('<gpx'));
        expect(
          controller.completedGpx,
          contains('<trkpt lat="41.1" lon="-8.6">'),
        );
        expect(controller.state.localActivityId, 'local_complete');
        expect(records, hasLength(1));
        expect(records.single.id, 'local_complete');
        expect(await repository.hasGpx(records.single), isTrue);
      },
    );

    test('does not generate GPX for discarded recordings', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = _recordingService(adapter: adapter);
      final controller = ActivityRecordingController(recordingService: service);
      addTearDown(controller.dispose);

      await controller.start(ActivityType.run);
      adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
      await pumpEventQueue();
      await controller.discard();

      expect(controller.state.status, ActivityRecordingStatus.idle);
      expect(controller.completedGpx, isNull);
    });

    test('leaves empty recordings without GPX content', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = _recordingService(adapter: adapter);
      final controller = ActivityRecordingController(recordingService: service);
      addTearDown(controller.dispose);

      await controller.start(ActivityType.run);
      await controller.stop();
      await pumpEventQueue();

      expect(controller.state.status, ActivityRecordingStatus.failed);
      expect(controller.completedGpx, isNull);
    });

    test('surfaces GPX generation failures as recording failures', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = _recordingService(adapter: adapter);
      final diagnostics = _CapturingDiagnosticsRecorder();
      final controller = ActivityRecordingController(
        recordingService: service,
        gpxBuilder: const _ThrowingGpxBuilder(),
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.start(ActivityType.run);
      adapter.addPosition(recordingPosition());
      await pumpEventQueue();
      await controller.stop();

      expect(controller.state.status, ActivityRecordingStatus.failed);
      expect(
        controller.state.lastError,
        ActivityRecordingError.gpxGenerationFailed,
      );
      expect(controller.completedGpx, isNull);
      expect(controller.uploadStatus, ActivityUploadStatus.idle);
      // M2: a sanitized breadcrumb (error type only, no coordinates) is
      // recorded so the failure is observable in a field report.
      final breadcrumb = diagnostics.breadcrumbs.singleWhere(
        (entry) => entry.event == DiagnosticsEvents.activityGpxGenerationFailed,
      );
      expect(breadcrumb.details['type'], 'StateError');
    });

    test('surfaces local save failures before upload starts', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = _recordingService(adapter: adapter);
      final controller = ActivityRecordingController(
        recordingService: service,
        localActivityRepository: _ThrowingLocalActivityRepository(),
        uploadService: _uploadServiceReturning(201),
      );
      addTearDown(controller.dispose);

      await controller.start(ActivityType.run);
      adapter.addPosition(recordingPosition());
      await pumpEventQueue();
      await controller.stop();

      expect(controller.state.status, ActivityRecordingStatus.failed);
      expect(
        controller.state.lastError,
        ActivityRecordingError.localSaveFailed,
      );
      expect(controller.uploadStatus, ActivityUploadStatus.failed);
      expect(
        controller.uploadError,
        isA<AppException>().having(
          (exception) => exception.code,
          'code',
          AppErrorCode.activityLocalSaveFailed,
        ),
      );
    });

    test(
      'localSaveFailed is terminal: stopping/completed transitions are ignored',
      () async {
        // Arrange: controller whose repository always throws on write, so
        // stop() results in failed/localSaveFailed.
        final adapter = RecordingLocationPlatformAdapter();
        final service = _recordingService(adapter: adapter);
        final controller = ActivityRecordingController(
          recordingService: service,
          localActivityRepository: _ThrowingLocalActivityRepository(),
          uploadService: _uploadServiceReturning(201),
        );
        addTearDown(controller.dispose);

        await controller.start(ActivityType.run);
        adapter.addPosition(recordingPosition());
        await pumpEventQueue();
        await controller.stop();

        // Pre-condition: terminal state reached.
        expect(controller.state.status, ActivityRecordingStatus.failed);
        expect(
          controller.state.lastError,
          ActivityRecordingError.localSaveFailed,
        );

        // Act: attempt to push the state back to stopping or completed —
        // this exercises the _setState guard directly by trying an upload.
        await controller.uploadCompletedGpx();

        // Assert: state must remain failed/localSaveFailed; upload attempt
        // should have bailed immediately without changing the status.
        expect(controller.state.status, ActivityRecordingStatus.failed);
        expect(
          controller.state.lastError,
          ActivityRecordingError.localSaveFailed,
        );
      },
    );

    test(
      'marks retained record uploaded and keeps GPX after successful upload',
      () async {
        final adapter = RecordingLocationPlatformAdapter();
        final tempDirectory = await Directory.systemTemp.createTemp(
          'endurain_upload_success_',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
        final repository = _repositoryFor(tempDirectory);
        final service = _recordingService(adapter: adapter);
        final controller = ActivityRecordingController(
          recordingService: service,
          localActivityRepository: repository,
          localActivityIdProvider: () => 'upload_success',
          uploadService: _uploadServiceReturning(201),
        );
        addTearDown(controller.dispose);

        await controller.start(ActivityType.run);
        adapter.addPosition(recordingPosition());
        await pumpEventQueue();
        await controller.stop();
        await controller.uploadCompletedGpx();

        final record = (await repository.list()).single;
        expect(controller.uploadStatus, ActivityUploadStatus.uploaded);
        expect(record.uploadStatus, LocalActivityUploadStatus.uploaded);
        expect(record.uploadedAt, isNotNull);
        expect(record.lastUploadErrorCode, isNull);
        expect(await repository.hasGpx(record), isTrue);
      },
    );

    test('marks auth failures with safe local upload error code', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_upload_auth_failed_',
      );
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
      final repository = _repositoryFor(tempDirectory);
      final service = _recordingService(adapter: adapter);
      final controller = ActivityRecordingController(
        recordingService: service,
        localActivityRepository: repository,
        localActivityIdProvider: () => 'upload_auth_failed',
        uploadService: _uploadServiceReturning(401),
      );
      addTearDown(controller.dispose);

      await controller.start(ActivityType.run);
      adapter.addPosition(recordingPosition());
      await pumpEventQueue();
      await controller.stop();
      await controller.uploadCompletedGpx();

      final record = (await repository.list()).single;
      expect(controller.uploadStatus, ActivityUploadStatus.failed);
      expect(record.uploadStatus, LocalActivityUploadStatus.failed);
      expect(record.lastUploadErrorCode, AppErrorCode.sessionExpired);
      expect(await repository.hasGpx(record), isTrue);
    });

    test(
      'clearCompleted resets active state and preserves local record',
      () async {
        final adapter = RecordingLocationPlatformAdapter();
        final tempDirectory = await Directory.systemTemp.createTemp(
          'endurain_clear_completed_',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
        final repository = _repositoryFor(tempDirectory);
        final service = _recordingService(adapter: adapter);
        final controller = ActivityRecordingController(
          recordingService: service,
          localActivityRepository: repository,
          localActivityIdProvider: () => 'clear_completed',
          uploadService: _uploadServiceReturning(201),
        );
        addTearDown(controller.dispose);

        await controller.start(ActivityType.run);
        adapter.addPosition(recordingPosition());
        await pumpEventQueue();
        await controller.stop();
        await controller.uploadCompletedGpx();
        await controller.clearCompleted();

        final records = await repository.list();
        expect(controller.state.status, ActivityRecordingStatus.idle);
        expect(controller.completedGpx, isNull);
        expect(records, hasLength(1));
        expect(await repository.hasGpx(records.single), isTrue);
      },
    );

    test('discard deletes retained local record and GPX', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_discard_retained_',
      );
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
      final repository = _repositoryFor(tempDirectory);
      final service = _recordingService(adapter: adapter);
      final controller = ActivityRecordingController(
        recordingService: service,
        localActivityRepository: repository,
        localActivityIdProvider: () => 'discard_retained',
        uploadService: _uploadServiceReturning(500),
      );
      addTearDown(controller.dispose);

      await controller.start(ActivityType.run);
      adapter.addPosition(recordingPosition());
      await pumpEventQueue();
      await controller.stop();
      await controller.uploadCompletedGpx();
      expect(await repository.list(), hasLength(1));

      await controller.discard();

      expect(controller.state.status, ActivityRecordingStatus.idle);
      expect(await repository.list(), isEmpty);
    });

    test('retention setting removes uploaded GPX but keeps metadata', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_retention_disabled_',
      );
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
      final repository = _repositoryFor(tempDirectory);
      final service = _recordingService(adapter: adapter);
      final controller = ActivityRecordingController(
        recordingService: service,
        localActivityRepository: repository,
        localActivityIdProvider: () => 'retention_disabled',
        uploadService: _uploadServiceReturning(201),
        retentionSettingsRepository: _FakeRetentionSettings(enabled: false),
      );
      addTearDown(controller.dispose);

      await controller.start(ActivityType.run);
      adapter.addPosition(recordingPosition());
      await pumpEventQueue();
      await controller.stop();
      await controller.uploadCompletedGpx();

      final record = (await repository.list()).single;
      expect(record.uploadStatus, LocalActivityUploadStatus.uploaded);
      expect(await repository.hasGpx(record), isFalse);
    });

    test(
      'cleanup failure keeps upload successful and shows cleanup state',
      () async {
        final adapter = RecordingLocationPlatformAdapter();
        final tempDirectory = await Directory.systemTemp.createTemp(
          'endurain_cleanup_failed_',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
        final repository = _DeleteGpxThrowingRepository(tempDirectory);
        final service = _recordingService(adapter: adapter);
        final controller = ActivityRecordingController(
          recordingService: service,
          localActivityRepository: repository,
          localActivityIdProvider: () => 'cleanup_failed',
          uploadService: _uploadServiceReturning(201),
          retentionSettingsRepository: _FakeRetentionSettings(enabled: false),
        );
        addTearDown(controller.dispose);

        await controller.start(ActivityType.run);
        adapter.addPosition(recordingPosition());
        await pumpEventQueue();
        await controller.stop();
        await controller.uploadCompletedGpx();

        final record = (await repository.list()).single;
        expect(controller.uploadStatus, ActivityUploadStatus.cleanupFailed);
        expect(
          controller.uploadError?.code,
          AppErrorCode.activityGpxCleanupFailed,
        );
        expect(record.uploadStatus, LocalActivityUploadStatus.uploaded);
        expect(
          record.lastUploadErrorCode,
          AppErrorCode.activityGpxCleanupFailed,
        );
        expect(await repository.hasGpx(record), isTrue);
      },
    );

    test('5xx upload is retried and succeeds on second attempt', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_retry_5xx_',
      );
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
      final repository = _repositoryFor(tempDirectory);
      final service = _recordingService(adapter: adapter);
      final controller = ActivityRecordingController(
        recordingService: service,
        localActivityRepository: repository,
        localActivityIdProvider: () => 'retry_5xx',
        uploadService: _uploadServiceWithResponses([500, 201]),
      );
      addTearDown(controller.dispose);

      await controller.start(ActivityType.run);
      adapter.addPosition(recordingPosition());
      await pumpEventQueue();
      await controller.stop();
      await controller.uploadCompletedGpx();

      final records = await repository.list();
      expect(records.single.uploadStatus, LocalActivityUploadStatus.uploaded);
      expect(controller.uploadStatus, ActivityUploadStatus.uploaded);
    });
  });
}

class _ThrowingGpxBuilder extends ActivityGpxBuilder {
  const _ThrowingGpxBuilder();

  @override
  String build(ActivityRecordingState state, {String? trackName}) {
    throw StateError('GPX generation failed');
  }
}

class _CapturingDiagnosticsRecorder implements DiagnosticsRecorder {
  final List<DiagnosticsBreadcrumb> breadcrumbs = [];

  @override
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  }) {
    breadcrumbs.add(
      DiagnosticsBreadcrumb(at: null, event: event, details: details),
    );
  }

  @override
  void recordErrorSync(
    Object error,
    StackTrace stackTrace, {
    String source = DiagnosticsSources.uncaught,
  }) {}
}

class _ThrowingLocalActivityRepository extends LocalActivityRepository {
  _ThrowingLocalActivityRepository()
    : super(supportDirectoryProvider: () async => Directory.systemTemp);

  @override
  Future<String> writeGpx({required String id, required String gpx}) {
    throw const AppException(AppErrorCode.activityLocalSaveFailed);
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

class _FakeRetentionSettings extends ActivityRetentionSettingsRepository {
  _FakeRetentionSettings({required this.enabled})
    : super(storage: SecureStorageService());

  final bool enabled;

  @override
  Future<bool> isRetainUploadedGpxEnabled() async => enabled;

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {}
}

ActivityRecordingService _recordingService({
  RecordingLocationPlatformAdapter? adapter,
  ActiveActivityStore? store,
}) {
  final locationService = LocationService(
    platformAdapter: adapter ?? RecordingLocationPlatformAdapter(),
  );
  final activeStore = store ?? InMemoryActiveActivityStore();
  return ActivityRecordingService(
    recorder: GeolocatorActivityLocationRecorder(
      store: activeStore,
      locationService: locationService,
    ),
    locationService: locationService,
  );
}

LocalActivityRepository _repositoryFor(Directory directory) {
  return createTestLocalActivityRepository(directory);
}

ActivityRecordingController _controllerWithActiveStore(
  ActiveActivityStore store,
) {
  return ActivityRecordingController(
    recordingService: _recordingService(store: store),
  );
}

ActiveActivitySession _activeSession(ActiveActivityStatus status) {
  return ActiveActivitySession(
    localSessionId: 'session_1',
    activityType: ActivityType.ride,
    status: status,
    startedAt: DateTime.utc(2026, 6, 3, 9),
    elapsedDurationSeconds: 120,
  );
}

RecordedActivityPoint _recordedPoint({
  required int segmentIndex,
  required double latitude,
}) {
  return RecordedActivityPoint(
    timestamp: DateTime.utc(2026, 6, 3, 9),
    latitude: latitude,
    longitude: -8,
    segmentIndex: segmentIndex,
  );
}

ActivityUploadService _uploadServiceReturning(int statusCode) {
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    uploadFile: (_, _, _, {idempotencyKey}) async {
      return http.StreamedResponse(const Stream<List<int>>.empty(), statusCode);
    },
  );
}

ActivityUploadService _uploadServiceWithResponses(List<int> statusCodes) {
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
