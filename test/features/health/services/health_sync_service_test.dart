import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/repositories/sqflite_activity_store.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';
import 'package:endurain/features/health/services/health_sync_service.dart';
import 'package:endurain/features/health/services/health_workout_gpx_builder.dart';

import '../fakes/fake_health_import_store.dart';
import '../fakes/fake_health_platform_adapter.dart';
import '../../../helpers/fake_preferences_store.dart';

// Fake ActivityUploadQueue that records drain() calls.
class _FakeUploadQueue extends ActivityUploadQueue {
  int drainCount = 0;

  _FakeUploadQueue(LocalActivityRepository repository)
    : super(repository: repository, uploadService: ActivityUploadService());

  @override
  Future<void> drain() async => drainCount++;
}

void main() {
  const origin = 'https://example.test';
  const profile = ConnectionProfile(
    id: 'profile-1',
    origin: origin,
    kind: ConnectionKind.selfHosted,
  );
  sqfliteFfiInit();
  TestWidgetsFlutterBinding.ensureInitialized();

  final start = DateTime.utc(2025, 6, 1, 9, 0);
  final end = DateTime.utc(2025, 6, 1, 10, 0);

  HealthWorkout makeWorkout(String id, {bool hasRoute = true}) => HealthWorkout(
    sourceId: id,
    type: HealthWorkoutType.run,
    startedAt: start,
    endedAt: end,
    route: hasRoute
        ? [HealthRoutePoint(latitude: 38.0, longitude: -9.0, time: start)]
        : const [],
  );

  late Directory tempDir;
  late LocalActivityRepository localActivities;
  late FakeHealthImportStore importStore;
  late FakeHealthPlatformAdapter adapter;
  late _FakeUploadQueue uploadQueue;
  late HealthSyncService service;
  late FakePreferencesStore healthPrefs;
  late SecureStorageService healthStorage;

  HealthSyncSettingsRepository makeSyncSettings() {
    return HealthSyncSettingsRepository(
      preferences: healthPrefs,
      storage: healthStorage,
    );
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    healthPrefs = FakePreferencesStore();
    healthStorage = SecureStorageService();
    tempDir = await Directory.systemTemp.createTemp('health_sync_test_');
    final activityStore = SqfliteActivityStore(
      databaseFactory: databaseFactoryFfiNoIsolate,
      databasePath: '${tempDir.path}${Platform.pathSeparator}activity.db',
    );
    localActivities = LocalActivityRepository(
      supportDirectoryProvider: () async => tempDir,
      store: activityStore,
    );
    importStore = FakeHealthImportStore();
    adapter = FakeHealthPlatformAdapter(
      sdkStatus: HealthSdkStatus.available,
      authStatus: HealthAuthorizationStatus.granted,
    );
    uploadQueue = _FakeUploadQueue(localActivities);

    service = HealthSyncService(
      adapter: adapter,
      importRepository: HealthImportRepository(store: importStore),
      localActivities: localActivities,
      uploadQueue: uploadQueue,
      gpxBuilder: const HealthWorkoutGpxBuilder(),
      syncSettings: makeSyncSettings(),
      diagnostics: const NoopDiagnosticsRecorder(),
      healthSyncEnabled: true,
      activeConnectionProfile: () async => profile,
      now: () => DateTime.utc(2025, 6, 1, 11, 0),
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ── I1: Feature flag ───────────────────────────────────────────────────────

  group('feature flag off', () {
    late HealthSyncService disabledService;

    setUp(() {
      disabledService = HealthSyncService(
        adapter: adapter,
        importRepository: HealthImportRepository(store: importStore),
        localActivities: localActivities,
        uploadQueue: uploadQueue,
        gpxBuilder: const HealthWorkoutGpxBuilder(),
        syncSettings: makeSyncSettings(),
        diagnostics: const NoopDiagnosticsRecorder(),
        healthSyncEnabled: false,
        activeConnectionProfile: () async => profile,
        now: () => DateTime.utc(2025, 6, 1, 11, 0),
      );
    });

    test('status returns unsupported without calling adapter', () async {
      expect(await disabledService.status(), HealthSdkStatus.unsupported);
      expect(adapter.getSdkStatusCallCount, 0);
    });

    test('listImportable returns empty without calling adapter', () async {
      adapter.workouts = [makeWorkout('w1')];
      final result = await disabledService.listImportable();
      expect(result, isEmpty);
      expect(adapter.readWorkoutsCallCount, 0);
    });

    test('importWorkouts returns zero counts', () async {
      adapter.workouts = [makeWorkout('w1')];
      await disabledService.listImportable();
      final result = await disabledService.importWorkouts(['w1']);
      expect(result.imported, 0);
      expect(result.failed, 0);
    });
  });

  // ── I2: requestAccess ─────────────────────────────────────────────────────

  group('requestAccess', () {
    test('returns granted when adapter grants access', () async {
      adapter.authStatus = HealthAuthorizationStatus.granted;
      final result = await service.requestAccess();
      expect(result, HealthAuthorizationStatus.granted);
      expect(adapter.requestAuthorizationCallCount, 1);
    });

    test('returns denied when adapter denies access', () async {
      adapter.authStatus = HealthAuthorizationStatus.denied;
      final result = await service.requestAccess();
      expect(result, HealthAuthorizationStatus.denied);
    });

    test('persists the connected flag when access is granted', () async {
      adapter.authStatus = HealthAuthorizationStatus.granted;
      await service.requestAccess();

      final settings = makeSyncSettings();
      expect(await settings.isConnected(profile.id), isTrue);
    });

    test('does not persist connected when access is denied', () async {
      adapter.authStatus = HealthAuthorizationStatus.denied;
      await service.requestAccess();

      final settings = makeSyncSettings();
      expect(await settings.isConnected(profile.id), isFalse);
    });
  });

  // ── currentAuthorizationStatus (iOS read-grant resolution) ─────────────────

  group('currentAuthorizationStatus', () {
    test('returns granted when the platform reports granted', () async {
      adapter.authStatus = HealthAuthorizationStatus.granted;
      expect(
        await service.currentAuthorizationStatus(),
        HealthAuthorizationStatus.granted,
      );
    });

    test(
      'treats notDetermined as granted once the user has connected',
      () async {
        adapter.authStatus = HealthAuthorizationStatus.notDetermined;
        await makeSyncSettings().setConnected(profile.id, true);

        expect(
          await service.currentAuthorizationStatus(),
          HealthAuthorizationStatus.granted,
        );
      },
    );

    test('keeps notDetermined when the user has not connected', () async {
      adapter.authStatus = HealthAuthorizationStatus.notDetermined;
      expect(
        await service.currentAuthorizationStatus(),
        HealthAuthorizationStatus.notDetermined,
      );
    });

    test('respects a platform denial even when previously connected', () async {
      adapter.authStatus = HealthAuthorizationStatus.denied;
      await makeSyncSettings().setConnected(profile.id, true);

      expect(
        await service.currentAuthorizationStatus(),
        HealthAuthorizationStatus.denied,
      );
    });
  });

  // ── I3: listImportable ────────────────────────────────────────────────────

  group('listImportable', () {
    test('excludes already-imported workouts', () async {
      adapter.workouts = [makeWorkout('w1'), makeWorkout('w2')];
      await service.importAll();
      adapter.workouts = [makeWorkout('w1'), makeWorkout('w2')];

      final result = await service.listImportable();
      expect(result, isEmpty);
    });

    test('loads a wider range in 30-day chunks', () async {
      adapter.workoutPages = [
        [makeWorkout('recent')],
        [makeWorkout('older')],
      ];

      final first = await service.loadAvailable(
        range: const HealthImportRange.last3Months(),
      );
      final second = await service.loadMoreAvailable();

      expect(adapter.readWindows, hasLength(2));
      expect(
        adapter.readWindows.first.end.difference(
          adapter.readWindows.first.start,
        ),
        lessThanOrEqualTo(const Duration(days: 30)),
      );
      expect(first.items.map((workout) => workout.sourceId), ['recent']);
      expect(second.items.map((workout) => workout.sourceId).toSet(), {
        'recent',
        'older',
      });
      expect(second.hasMore, isTrue);
    });

    test(
      'keeps a missing imported record hidden until explicit restore',
      () async {
        adapter.workouts = [makeWorkout('w1')];
        await importStore.markImported(
          profileId: profile.id,
          sourceId: 'w1',
          localActivityId: 'missing-local',
        );

        final result = await service.listImportable();

        expect(result, isEmpty);
        expect(
          await importStore.isImported(profileId: profile.id, sourceId: 'w1'),
          isTrue,
        );

        final imported = (await service.listImported()).items.single;
        expect(imported.localActivity, isNull);
        await service.restoreMissingImport(imported);

        final restored = await service.listImportable();
        expect(restored.map((workout) => workout.sourceId), ['w1']);
      },
    );

    test('includes no-route workouts as non-importable candidates', () async {
      adapter.workouts = [
        makeWorkout('w1', hasRoute: false),
        makeWorkout('w2'),
      ];
      final result = await service.listImportable();
      expect(result, hasLength(2));
      expect(result.where((w) => w.hasRoute), hasLength(1));
      expect(result.where((w) => !w.hasRoute), hasLength(1));
    });

    test('exposes route consent denied count from adapter', () async {
      adapter.routeConsentDeniedCountValue = 2;
      adapter.workouts = [makeWorkout('w1', hasRoute: false)];

      await service.listImportable();

      expect(service.routeConsentDeniedCount, 2);
    });

    test(
      'clearDiscoveryCache drops cached candidates and consent count',
      () async {
        adapter.routeConsentDeniedCountValue = 2;
        adapter.workouts = [makeWorkout('w1', hasRoute: false)];
        await service.listImportable();
        expect(service.routeConsentDeniedCount, 2);

        await service.clearDiscoveryCache();

        expect(service.routeConsentDeniedCount, 0);
      },
    );

    test('returns empty list when no workouts from adapter', () async {
      adapter.workouts = [];
      expect(await service.listImportable(), isEmpty);
    });

    test('clears a stale connection when reading health data fails', () async {
      final settings = makeSyncSettings();
      await settings.setConnected(profile.id, true);
      adapter.readWorkoutsError = const AppException(
        AppErrorCode.healthReadFailed,
      );

      await expectLater(service.listImportable(), throwsA(isA<AppException>()));

      expect(await settings.isConnected(profile.id), isFalse);
    });
  });

  // ── I4: importWorkouts ────────────────────────────────────────────────────

  group('importWorkouts', () {
    test('persists exactly the selected route-bearing workouts', () async {
      adapter.workouts = [
        makeWorkout('w1'),
        makeWorkout('w2'),
        makeWorkout('w3'),
      ];
      await service.listImportable();

      final result = await service.importWorkouts(['w1', 'w2']);

      expect(result.imported, 2);
      expect(result.failed, 0);
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w1'),
        isTrue,
      );
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w2'),
        isTrue,
      );
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w3'),
        isFalse,
      );

      final pending = await localActivities.listByUploadStatus({
        LocalActivityUploadStatus.pending,
      });
      expect(pending, hasLength(2));
    });

    test('derives a stable idempotency key from the source workout', () async {
      adapter.workouts = [makeWorkout('w1')];
      await service.listImportable();
      await service.importWorkouts(['w1']);

      final pending = await localActivities.listByUploadStatus({
        LocalActivityUploadStatus.pending,
      });
      expect(pending.single.idempotencyKey, startsWith('health_'));
      expect(pending.single.idempotencyKey, isNot(contains('w1')));
      expect(
        pending.single.effectiveIdempotencyKey,
        pending.single.idempotencyKey,
      );
      expect(pending.single.id, pending.single.idempotencyKey);
    });

    test('skips no-route workouts', () async {
      adapter.workouts = [makeWorkout('w1', hasRoute: false)];
      await service.listImportable();

      final result = await service.importWorkouts(['w1']);
      expect(result.imported, 0);
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w1'),
        isFalse,
      );
    });

    test('drain is called after successful imports', () async {
      adapter.workouts = [makeWorkout('w1')];
      await service.listImportable();
      uploadQueue.drainCount = 0;

      await service.importWorkouts(['w1']);
      await Future<void>.delayed(Duration.zero); // let unawaited drain fire
      expect(uploadQueue.drainCount, 1);
    });

    test(
      'unselected workouts are still importable on next listImportable',
      () async {
        adapter.workouts = [makeWorkout('w1'), makeWorkout('w2')];
        await service.listImportable();
        await service.importWorkouts(['w1']);

        final candidates = await service.listImportable();
        expect(candidates.map((w) => w.sourceId), contains('w2'));
        expect(candidates.map((w) => w.sourceId), isNot(contains('w1')));
      },
    );
  });

  // ── I5: importAll ─────────────────────────────────────────────────────────

  group('importAll', () {
    test('always discovers only the default range', () async {
      adapter.workoutPages = [
        [makeWorkout('wide')],
        [makeWorkout('recent')],
      ];
      await service.loadAvailable(range: const HealthImportRange.lastYear());

      final result = await service.importAll();

      expect(result.imported, 1);
      expect(adapter.readWindows, hasLength(2));
      expect(
        adapter.readWindows.last.end.difference(adapter.readWindows.last.start),
        lessThanOrEqualTo(const Duration(days: 30)),
      );
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'recent'),
        isTrue,
      );
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'wide'),
        isFalse,
      );
    });

    test('imports all route-bearing candidates from listImportable', () async {
      adapter.workouts = [
        makeWorkout('w1'),
        makeWorkout('w2'),
        makeWorkout('w3', hasRoute: false),
      ];
      await service.listImportable();

      final result = await service.importAll();

      expect(result.imported, 2);
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w1'),
        isTrue,
      );
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w2'),
        isTrue,
      );
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w3'),
        isFalse,
      );
    });

    test('loads candidates before importing when no preview was run', () async {
      adapter.workouts = [makeWorkout('w1'), makeWorkout('w2')];

      final result = await service.importAll();

      expect(result.imported, 2);
      expect(adapter.readWorkoutsCallCount, 1);
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w1'),
        isTrue,
      );
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w2'),
        isTrue,
      );
    });

    test('returns zero when no importable workouts', () async {
      adapter.workouts = [];
      final result = await service.importAll();
      expect(result.imported, 0);
    });
  });

  group('autoSyncOnResume', () {
    test('does nothing while the profile setting is disabled', () async {
      adapter.workouts = [makeWorkout('w1')];

      final result = await service.autoSyncOnResume();

      expect(result, isNull);
      expect(adapter.currentAuthorizationStatusCallCount, 0);
      expect(adapter.readWorkoutsCallCount, 0);
    });

    test('does nothing when health authorization is unavailable', () async {
      await service.setAutoSyncOnResumeEnabled(true);
      adapter.authStatus = HealthAuthorizationStatus.denied;
      adapter.workouts = [makeWorkout('w1')];

      final result = await service.autoSyncOnResume();

      expect(result, isNull);
      expect(adapter.readWorkoutsCallCount, 0);
    });

    test('imports the bounded default range when enabled', () async {
      await service.setAutoSyncOnResumeEnabled(true);
      adapter.workouts = [makeWorkout('w1')];

      final result = await service.autoSyncOnResume();

      expect(result?.imported, 1);
      expect(adapter.readWindows, hasLength(1));
      expect(
        adapter.readWindows.single.end.difference(
          adapter.readWindows.single.start,
        ),
        lessThanOrEqualTo(const Duration(days: 30)),
      );
    });

    test('rejects a profile switch while authorization is in flight', () async {
      var activeProfile = const ConnectionProfile(
        id: 'profile-a',
        origin: origin,
        kind: ConnectionKind.selfHosted,
      );
      final scopedService = HealthSyncService(
        adapter: adapter,
        importRepository: HealthImportRepository(store: importStore),
        localActivities: localActivities,
        uploadQueue: uploadQueue,
        gpxBuilder: const HealthWorkoutGpxBuilder(),
        syncSettings: makeSyncSettings(),
        diagnostics: const NoopDiagnosticsRecorder(),
        healthSyncEnabled: true,
        activeConnectionProfile: () async => activeProfile,
        now: () => DateTime.utc(2025, 6, 1, 11),
      );
      await scopedService.setAutoSyncOnResumeEnabled(true);
      final authorization = Completer<HealthAuthorizationStatus>();
      adapter.currentAuthorizationStatusFuture = authorization.future;

      final result = scopedService.autoSyncOnResume();
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
    });
  });

  group('connection ownership and coordination', () {
    test('guest mode cannot discover or import health data', () async {
      final guestService = HealthSyncService(
        adapter: adapter,
        importRepository: HealthImportRepository(store: importStore),
        localActivities: localActivities,
        uploadQueue: uploadQueue,
        gpxBuilder: const HealthWorkoutGpxBuilder(),
        syncSettings: makeSyncSettings(),
        diagnostics: const NoopDiagnosticsRecorder(),
        healthSyncEnabled: true,
        activeConnectionProfile: () async => null,
      );
      adapter.workouts = [makeWorkout('w1')];

      await expectLater(
        guestService.listImportable(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
      expect(adapter.readWorkoutsCallCount, 0);
    });

    test(
      'the same source workout remains independent across login profiles',
      () async {
        var activeProfile = const ConnectionProfile(
          id: 'profile-a',
          origin: 'https://same.example',
          kind: ConnectionKind.selfHosted,
        );
        final scopedService = HealthSyncService(
          adapter: adapter,
          importRepository: HealthImportRepository(store: importStore),
          localActivities: localActivities,
          uploadQueue: uploadQueue,
          gpxBuilder: const HealthWorkoutGpxBuilder(),
          syncSettings: makeSyncSettings(),
          diagnostics: const NoopDiagnosticsRecorder(),
          healthSyncEnabled: true,
          activeConnectionProfile: () async => activeProfile,
          now: () => DateTime.utc(2025, 6, 1, 11),
        );
        adapter.workouts = [makeWorkout('w1')];

        await scopedService.importAll();
        activeProfile = const ConnectionProfile(
          id: 'profile-b',
          origin: 'https://same.example',
          kind: ConnectionKind.selfHosted,
        );
        final candidates = await scopedService.listImportable();

        expect(candidates.map((workout) => workout.sourceId), contains('w1'));
        expect(
          await importStore.isImported(profileId: 'profile-a', sourceId: 'w1'),
          isTrue,
        );
        expect(
          await importStore.isImported(profileId: 'profile-b', sourceId: 'w1'),
          isFalse,
        );
      },
    );

    test('distinct concurrent selections are serialized, not merged', () async {
      adapter.workouts = [makeWorkout('w1'), makeWorkout('w2')];
      await service.listImportable();

      final results = await Future.wait([
        service.importWorkouts(['w1']),
        service.importWorkouts(['w2']),
      ]);

      expect(results.fold<int>(0, (sum, result) => sum + result.imported), 2);
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w1'),
        isTrue,
      );
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w2'),
        isTrue,
      );
    });

    test('disconnect revokes access and clears active-origin state', () async {
      await service.requestAccess();
      await service.setAutoSyncOnResumeEnabled(true);
      adapter.workouts = [makeWorkout('w1')];
      await service.importAll();

      await service.disconnect();

      expect(adapter.revokePermissionsCallCount, 1);
      expect(await makeSyncSettings().isConnected(profile.id), isFalse);
      expect(await service.isAutoSyncOnResumeEnabled(), isFalse);
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w1'),
        isFalse,
      );
    });
  });

  group('imported history', () {
    test('joins imported rows to local activity status', () async {
      adapter.workouts = [makeWorkout('w1')];
      await service.importAll();

      final page = await service.listImported();

      expect(page.items, hasLength(1));
      expect(page.items.single.sourceId, 'w1');
      expect(page.items.single.localActivity, isNotNull);
      expect(
        page.items.single.localActivity?.uploadStatus,
        LocalActivityUploadStatus.pending,
      );
    });

    test('restores only after the local activity is missing', () async {
      adapter.workouts = [makeWorkout('w1')];
      await service.importAll();
      final imported = (await service.listImported()).items.single;

      await expectLater(
        service.restoreMissingImport(imported),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.healthImportFailed,
          ),
        ),
      );

      await localActivities.delete(imported.localActivityId);
      await service.restoreMissingImport(imported);
      expect(
        await importStore.isImported(profileId: profile.id, sourceId: 'w1'),
        isFalse,
      );
    });

    test('rejects restore after the active profile changes', () async {
      var activeProfile = const ConnectionProfile(
        id: 'profile-a',
        origin: origin,
        kind: ConnectionKind.selfHosted,
      );
      final scopedService = HealthSyncService(
        adapter: adapter,
        importRepository: HealthImportRepository(store: importStore),
        localActivities: localActivities,
        uploadQueue: uploadQueue,
        gpxBuilder: const HealthWorkoutGpxBuilder(),
        syncSettings: makeSyncSettings(),
        diagnostics: const NoopDiagnosticsRecorder(),
        healthSyncEnabled: true,
        activeConnectionProfile: () async => activeProfile,
        now: () => DateTime.utc(2025, 6, 1, 11),
      );
      adapter.workouts = [makeWorkout('w1')];
      await scopedService.importAll();
      final imported = (await scopedService.listImported()).items.single;
      await localActivities.delete(imported.localActivityId);

      activeProfile = const ConnectionProfile(
        id: 'profile-b',
        origin: origin,
        kind: ConnectionKind.selfHosted,
      );

      await expectLater(
        scopedService.restoreMissingImport(imported),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.healthImportFailed,
          ),
        ),
      );
      expect(
        await importStore.isImported(profileId: 'profile-a', sourceId: 'w1'),
        isTrue,
      );
    });
  });
}
