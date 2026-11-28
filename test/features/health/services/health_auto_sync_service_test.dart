import 'dart:async';
import 'dart:io';

import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/repositories/sqflite_activity_store.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_changes.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';
import 'package:endurain/features/health/services/health_auto_sync_service.dart';
import 'package:endurain/features/health/services/health_background_sync_adapter.dart';
import 'package:endurain/features/health/services/health_sync_service.dart';
import 'package:endurain/features/health/services/health_workout_gpx_builder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../../../helpers/recording_diagnostics.dart';
import '../fakes/fake_health_import_store.dart';
import '../fakes/fake_health_platform_adapter.dart';

class _FakeUploadQueue extends ActivityUploadQueue {
  _FakeUploadQueue(LocalActivityRepository repository)
    : super(repository: repository, uploadService: ActivityUploadService());

  /// What [drain] waits for; an upload still in flight when set.
  Future<void>? uploading;

  /// Completes when an upload is first asked for.
  final Completer<void> drainRequested = Completer<void>();

  @override
  Future<void> drain() {
    if (!drainRequested.isCompleted) drainRequested.complete();
    return uploading ?? Future.value();
  }
}

/// Records what the service asks of the native background trigger.
class _FakeBackgroundSync implements HealthBackgroundSyncAdapter {
  final List<bool> scheduled = [];
  Error? setScheduledError;

  @override
  Future<void> setScheduled(bool scheduled) async {
    if (setScheduledError case final error?) throw error;
    this.scheduled.add(scheduled);
  }

  @override
  Future<void> listen(Future<bool> Function() run) async {}

  @override
  Future<void> reportFinished({required bool succeeded}) async {}
}

void main() {
  const origin = 'https://example.test';
  const profile = ConnectionProfile(
    id: 'profile-1',
    origin: origin,
    kind: ConnectionKind.selfHosted,
  );
  final now = DateTime.utc(2025, 6, 1, 11);
  final defaultStart = now.subtract(const Duration(days: 30));
  sqfliteFfiInit();
  TestWidgetsFlutterBinding.ensureInitialized();

  HealthWorkout makeWorkout(String id, {DateTime? startedAt}) {
    final start = startedAt ?? DateTime.utc(2025, 6, 1, 9);
    return HealthWorkout(
      sourceId: id,
      type: HealthWorkoutType.run,
      startedAt: start,
      endedAt: start.add(const Duration(hours: 1)),
      route: [HealthRoutePoint(latitude: 38.0, longitude: -9.0, time: start)],
    );
  }

  late Directory tempDir;
  late FakeHealthImportStore importStore;
  late FakeHealthPlatformAdapter adapter;
  late _FakeUploadQueue uploadQueue;
  late _FakeBackgroundSync background;
  late RecordingDiagnostics diagnostics;
  late HealthSyncSettingsRepository settings;
  late HealthSyncService syncService;
  late ConnectionProfile? activeProfile;
  late HealthAutoSyncService service;

  HealthAutoSyncService makeService({bool healthSyncEnabled = true}) {
    return HealthAutoSyncService(
      syncService: syncService,
      adapter: adapter,
      background: background,
      settings: settings,
      importRepository: HealthImportRepository(store: importStore),
      uploadQueue: uploadQueue,
      diagnostics: diagnostics,
      healthSyncEnabled: healthSyncEnabled,
      activeConnectionProfile: () async => activeProfile,
      now: () => now,
    );
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('health_auto_sync_test_');
    final localActivities = LocalActivityRepository(
      supportDirectoryProvider: () async => tempDir,
      store: SqfliteActivityStore(
        databaseFactory: databaseFactoryFfiNoIsolate,
        databasePath: '${tempDir.path}${Platform.pathSeparator}activity.db',
      ),
    );
    importStore = FakeHealthImportStore();
    adapter = FakeHealthPlatformAdapter(
      sdkStatus: HealthSdkStatus.available,
      authStatus: HealthAuthorizationStatus.granted,
    );
    uploadQueue = _FakeUploadQueue(localActivities);
    background = _FakeBackgroundSync();
    diagnostics = RecordingDiagnostics();
    settings = HealthSyncSettingsRepository(
      preferences: FakePreferencesStore(),
      storage: SecureStorageService(),
    );
    activeProfile = profile;
    syncService = HealthSyncService(
      adapter: adapter,
      importRepository: HealthImportRepository(store: importStore),
      localActivities: localActivities,
      uploadQueue: uploadQueue,
      gpxBuilder: const HealthWorkoutGpxBuilder(),
      syncSettings: settings,
      diagnostics: const NoopDiagnosticsRecorder(),
      healthSyncEnabled: true,
      activeConnectionProfile: () async => activeProfile,
      now: () => now,
    );
    service = makeService();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<void> enable() => settings.setAutoSyncEnabled(profile.id, true);

  group('setting', () {
    test('is off by default and when signed out', () async {
      expect(await service.isEnabled(), isFalse);
      await enable();
      expect(await service.isEnabled(), isTrue);

      activeProfile = null;
      expect(await service.isEnabled(), isFalse);
    });

    test('turning it on asks for background access and schedules', () async {
      await service.setEnabled(true);

      expect(await settings.isAutoSyncEnabled(profile.id), isTrue);
      expect(adapter.requestBackgroundReadAccessCallCount, 1);
      expect(background.scheduled, [true]);
    });

    test('a declined background permission keeps the resume import', () async {
      adapter.backgroundReadAccessOnRequest = false;

      await service.setEnabled(true);

      expect(await settings.isAutoSyncEnabled(profile.id), isTrue);
      expect(background.scheduled, [false]);
    });

    test('turning it off cancels the trigger without asking', () async {
      await service.setEnabled(false);

      expect(await settings.isAutoSyncEnabled(profile.id), isFalse);
      expect(adapter.requestBackgroundReadAccessCallCount, 0);
      expect(background.scheduled, [false]);
    });

    test('a failure to schedule is recorded and keeps the setting', () async {
      background.setScheduledError = StateError('no entitlement');

      await service.setEnabled(true);

      expect(await settings.isAutoSyncEnabled(profile.id), isTrue);
      expect(
        diagnostics.single(DiagnosticsEvents.healthBackgroundScheduleFailed),
        containsPair('scheduled', true),
      );
    });

    test('needs a signed-in profile', () async {
      activeProfile = null;

      await expectLater(
        service.setEnabled(true),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
    });
  });

  group('syncOnResume', () {
    test('does nothing while the setting is off', () async {
      adapter.workouts = [makeWorkout('w1')];

      final result = await service.syncOnResume();

      expect(result, isNull);
      expect(adapter.currentAuthorizationStatusCallCount, 0);
      expect(adapter.readWorkoutsCallCount, 0);
      expect(background.scheduled, [false]);
    });

    test('does nothing when health authorization is unavailable', () async {
      await enable();
      adapter.authStatus = HealthAuthorizationStatus.denied;
      adapter.workouts = [makeWorkout('w1')];

      final result = await service.syncOnResume();

      expect(result, isNull);
      expect(adapter.readWorkoutsCallCount, 0);
      expect(background.scheduled, [false]);
    });

    test('does nothing with the feature flag off', () async {
      await enable();

      final result = await makeService(healthSyncEnabled: false).syncOnResume();

      expect(result, isNull);
      expect(adapter.readWorkoutsCallCount, 0);
    });

    test('the first pass reads the default range and keeps a token', () async {
      await enable();
      adapter.workouts = [makeWorkout('w1')];

      final result = await service.syncOnResume();

      expect(result, (imported: 1, failed: 0));
      expect(adapter.readWindows.single.start, defaultStart);
      expect(await importStore.lastSyncAt(profile.id), now);
      expect(await settings.workoutChangesToken(profile.id), 'token-1');
      expect(background.scheduled, [true]);
    });

    test('without background access it leaves the trigger off', () async {
      await enable();
      adapter.backgroundReadAccess = false;

      await service.syncOnResume();

      expect(background.scheduled, [false]);
    });

    test('reads from the earliest changed workout on', () async {
      await enable();
      await settings.setWorkoutChangesToken(profile.id, 'token-1');
      final changedStart = DateTime.utc(2025, 5, 29, 7);
      adapter.changesByToken = {
        'token-1': HealthWorkoutChanges(
          nextToken: 'token-2',
          earliestStart: changedStart,
        ),
      };
      adapter.workouts = [makeWorkout('w1', startedAt: changedStart)];

      final result = await service.syncOnResume();

      expect(result, (imported: 1, failed: 0));
      expect(adapter.changesSinceTokens, ['token-1']);
      expect(adapter.workoutChangesTokenCallCount, 0);
      expect(adapter.readWindows.single.start, changedStart);
      expect(await settings.workoutChangesToken(profile.id), 'token-2');
    });

    test('reads nothing when nothing changed', () async {
      await enable();
      await settings.setWorkoutChangesToken(profile.id, 'token-1');
      await importStore.setLastSyncAt(profile.id, DateTime.utc(2025, 5, 30));
      adapter.changesByToken = {
        'token-1': const HealthWorkoutChanges(nextToken: 'token-2'),
      };

      final result = await service.syncOnResume();

      expect(result, (imported: 0, failed: 0));
      expect(adapter.readWorkoutsCallCount, 0);
      expect(await importStore.lastSyncAt(profile.id), now);
      expect(await settings.workoutChangesToken(profile.id), 'token-2');
    });

    test(
      'a change older than the default range reads only that range',
      () async {
        await enable();
        await settings.setWorkoutChangesToken(profile.id, 'token-1');
        adapter.changesByToken = {
          'token-1': HealthWorkoutChanges(
            nextToken: 'token-2',
            earliestStart: DateTime.utc(2025, 1, 1),
          ),
        };

        await service.syncOnResume();

        expect(adapter.readWindows.single.start, defaultStart);
      },
    );

    test(
      'an expired token reads 48 hours before the last sync and is replaced',
      () async {
        await enable();
        await settings.setWorkoutChangesToken(profile.id, 'old');
        await importStore.setLastSyncAt(
          profile.id,
          DateTime.utc(2025, 5, 30, 8),
        );
        adapter.changesByToken = {'old': const HealthWorkoutChanges.expired()};
        adapter.changesTokens = ['fresh'];

        await service.syncOnResume();

        expect(adapter.readWindows.single.start, DateTime.utc(2025, 5, 28, 8));
        expect(await settings.workoutChangesToken(profile.id), 'fresh');
      },
    );

    test('an old last sync never reaches past the default range', () async {
      await enable();
      await importStore.setLastSyncAt(profile.id, DateTime.utc(2025, 1, 1));

      await service.syncOnResume();

      expect(adapter.readWindows.single.start, defaultStart);
    });

    test('a failed pass keeps the last sync and the token', () async {
      await enable();
      await settings.setWorkoutChangesToken(profile.id, 'token-1');
      final previous = DateTime.utc(2025, 5, 30, 8);
      await importStore.setLastSyncAt(profile.id, previous);
      adapter.changesByToken = {
        'token-1': HealthWorkoutChanges(
          nextToken: 'token-2',
          earliestStart: DateTime.utc(2025, 5, 31),
        ),
      };
      adapter.readWorkoutsError = const AppException(
        AppErrorCode.healthReadFailed,
      );

      await expectLater(service.syncOnResume(), throwsA(isA<AppException>()));

      expect(await importStore.lastSyncAt(profile.id), previous);
      expect(await settings.workoutChangesToken(profile.id), 'token-1');
    });

    test('leaves the screen list and paging untouched', () async {
      await enable();
      adapter.workoutPages = [
        [makeWorkout('recent')],
        [makeWorkout('older')],
        [makeWorkout('recent')],
      ];
      await syncService.loadAvailable(
        range: const HealthImportRange.last3Months(),
      );
      await syncService.loadMoreAvailable();
      final secondPage = adapter.readWindows[1];

      final result = await service.syncOnResume();
      expect(result?.imported, 1);

      // The older workout, outside the default range, is still importable.
      expect(await syncService.importWorkouts(['older']), (
        imported: 1,
        failed: 0,
      ));

      // Paging continues the screen's range where it left off.
      await syncService.loadMoreAvailable();
      expect(
        adapter.readWindows.last.end,
        secondPage.start.subtract(const Duration(microseconds: 1)),
      );
    });

    test('rejects a profile switch while authorization is in flight', () async {
      await enable();
      final authorization = Completer<HealthAuthorizationStatus>();
      adapter.currentAuthorizationStatusFuture = authorization.future;

      final result = service.syncOnResume();
      while (adapter.currentAuthorizationStatusCallCount == 0) {
        await pumpEventQueue();
      }
      activeProfile = const ConnectionProfile(
        id: 'profile-b',
        origin: origin,
        kind: ConnectionKind.selfHosted,
      );
      authorization.complete(HealthAuthorizationStatus.granted);

      await expectLater(
        result,
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
      expect(adapter.readWorkoutsCallCount, 0);
      expect(await settings.workoutChangesToken(profile.id), isNull);
    });
  });

  group('syncInBackground', () {
    test('imports and waits for the uploads', () async {
      await enable();
      adapter.workouts = [makeWorkout('w1')];
      final upload = Completer<void>();
      uploadQueue.uploading = upload.future;
      var finished = false;

      final run = service.syncInBackground().whenComplete(
        () => finished = true,
      );
      await uploadQueue.drainRequested.future;

      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w1'),
        isTrue,
      );
      expect(finished, isFalse);
      upload.complete();
      expect(await run, isTrue);
      expect(background.scheduled, isEmpty);
    });

    test('turns the trigger off when the setting is off', () async {
      final succeeded = await service.syncInBackground();

      expect(succeeded, isTrue);
      expect(adapter.readWorkoutsCallCount, 0);
      expect(background.scheduled, [false]);
    });

    test('turns the trigger off when signed out', () async {
      await enable();
      activeProfile = null;

      expect(await service.syncInBackground(), isTrue);
      expect(background.scheduled, [false]);
    });

    test('reads nothing without background access', () async {
      await enable();
      adapter.backgroundReadAccess = false;
      adapter.workouts = [makeWorkout('w1')];

      expect(await service.syncInBackground(), isTrue);
      expect(adapter.readWorkoutsCallCount, 0);
      expect(background.scheduled, [false]);
    });

    test('records a failed pass and reports it', () async {
      await enable();
      adapter.readWorkoutsError = const AppException(
        AppErrorCode.healthReadFailed,
      );

      final succeeded = await service.syncInBackground();

      expect(succeeded, isFalse);
      expect(
        diagnostics.single(DiagnosticsEvents.healthBackgroundSyncFailed),
        isNotEmpty,
      );
      expect(background.scheduled, isEmpty);
    });
  });
}
