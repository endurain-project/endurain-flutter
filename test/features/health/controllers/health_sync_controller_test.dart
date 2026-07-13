import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_sync_state.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';

import '../fakes/fake_health_sync_service.dart';

void main() {
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

  late FakeHealthSyncService service;
  late HealthSyncController controller;

  setUp(() {
    service = FakeHealthSyncService(
      sdkStatus: HealthSdkStatus.available,
      authStatus: HealthAuthorizationStatus.notDetermined,
    );
    controller = HealthSyncController(
      service: service,
      diagnostics: const NoopDiagnosticsRecorder(),
    );
  });

  tearDown(() => controller.dispose());

  group('HealthSyncController', () {
    // ── loadStatus ──────────────────────────────────────────────────────────

    group('loadStatus', () {
      test('updates sdkStatus and authStatus on success', () async {
        service.authStatus = HealthAuthorizationStatus.granted;
        service.accessDetailsValue = const HealthDataAccessDetails(
          canInspectIndividualPermissions: true,
          workouts: HealthDataAccessStatus.allowed,
          workoutRoutes: HealthDataAccessStatus.needsAttention,
          heartRate: HealthDataAccessStatus.allowed,
        );
        await controller.loadStatus();

        expect(controller.state.sdkStatus, HealthSdkStatus.available);
        expect(controller.state.authStatus, HealthAuthorizationStatus.granted);
        expect(
          controller.state.accessDetails.workoutRoutes,
          HealthDataAccessStatus.needsAttention,
        );
        expect(controller.state.error, isNull);
      });

      test('stores error on failure', () async {
        service.nextError = const AppException(AppErrorCode.healthUnavailable);
        await controller.loadStatus();

        expect(controller.state.error, isNotNull);
        expect(controller.state.error!.code, AppErrorCode.healthUnavailable);
      });

      test('does not query authStatus when sdk is unsupported', () async {
        service.sdkStatus = HealthSdkStatus.unsupported;
        await controller.loadStatus();

        expect(controller.state.sdkStatus, HealthSdkStatus.unsupported);
        expect(
          controller.state.authStatus,
          HealthAuthorizationStatus.notDetermined,
        );
      });

      test('auto-loads importable workouts when access is granted', () async {
        service.authStatus = HealthAuthorizationStatus.granted;
        service.workouts = [makeWorkout('w1')];

        await controller.loadStatus();

        expect(service.listImportableCallCount, 1);
        expect(controller.state.importableWorkouts, hasLength(1));
      });

      test('does not load workouts when access is not granted', () async {
        service.authStatus = HealthAuthorizationStatus.denied;

        await controller.loadStatus();

        expect(service.listImportableCallCount, 0);
        expect(controller.state.importableWorkouts, isEmpty);
      });
    });

    group('range and views', () {
      test('changing range reloads available workouts', () async {
        service.authStatus = HealthAuthorizationStatus.granted;
        service.workouts = [makeWorkout('w1')];

        await controller.setRange(const HealthImportRange.last3Months());

        expect(
          controller.state.selectedRange.preset,
          HealthImportRangePreset.last3Months,
        );
        expect(service.lastRange?.preset, HealthImportRangePreset.last3Months);
        expect(service.loadAvailableCallCount, 1);
      });

      test('loadMoreAvailable appends the service page state', () async {
        service.authStatus = HealthAuthorizationStatus.granted;
        service.workouts = [makeWorkout('w1')];
        service.availableHasMore = true;
        await controller.loadImportableWorkouts();
        service.workouts = [makeWorkout('w1'), makeWorkout('w2')];

        await controller.loadMoreAvailable();

        expect(service.loadMoreAvailableCallCount, 1);
        expect(
          controller.state.importableWorkouts.map(
            (workout) => workout.sourceId,
          ),
          ['w1', 'w2'],
        );
        expect(controller.state.availableHasMore, isFalse);
      });

      test('selecting Imported loads its first page lazily', () async {
        service.importedWorkouts = [
          HealthImportedWorkout(
            sourceId: 'w1',
            localActivityId: 'local-1',
            importedAt: DateTime.utc(2026, 7, 1),
          ),
        ];

        await controller.selectView(HealthSyncView.imported);

        expect(controller.state.selectedView, HealthSyncView.imported);
        expect(service.listImportedCallCount, 1);
        expect(controller.state.importedWorkouts, hasLength(1));
      });

      test('restoring a missing import returns to Available', () async {
        final imported = HealthImportedWorkout(
          sourceId: 'w1',
          localActivityId: 'local-1',
          importedAt: DateTime.utc(2026, 7, 1),
        );
        service.importedWorkouts = [imported];
        service.workouts = [makeWorkout('w1')];
        await controller.selectView(HealthSyncView.imported);

        await controller.restoreMissingImport(imported);

        expect(service.restoreMissingImportCallCount, 1);
        expect(controller.state.selectedView, HealthSyncView.available);
        expect(controller.state.importableWorkouts, hasLength(1));
      });

      test('queue completion refreshes loaded imported statuses', () async {
        final uploadCompleted = StreamController<void>();
        addTearDown(uploadCompleted.close);
        controller.dispose();
        controller = HealthSyncController(
          service: service,
          diagnostics: const NoopDiagnosticsRecorder(),
          uploadCompletedSignal: uploadCompleted.stream,
        );
        service.importedWorkouts = [
          HealthImportedWorkout(
            sourceId: 'w1',
            localActivityId: 'local-1',
            importedAt: DateTime.utc(2026, 7, 1),
          ),
        ];
        await controller.selectView(HealthSyncView.imported);
        final callsBefore = service.listImportedCallCount;

        uploadCompleted.add(null);
        await pumpEventQueue();

        expect(service.listImportedCallCount, callsBefore + 1);
      });
    });

    // ── requestAccess ───────────────────────────────────────────────────────

    group('requestAccess', () {
      test('updates authStatus to granted', () async {
        service.authStatus = HealthAuthorizationStatus.granted;
        await controller.requestAccess();

        expect(controller.state.authStatus, HealthAuthorizationStatus.granted);
        expect(controller.state.error, isNull);
      });

      test('stores error when service throws', () async {
        service.nextError = const AppException(
          AppErrorCode.healthPermissionDenied,
        );
        await controller.requestAccess();

        expect(
          controller.state.error!.code,
          AppErrorCode.healthPermissionDenied,
        );
      });
    });

    // ── loadImportableWorkouts ──────────────────────────────────────────────

    group('loadImportableWorkouts', () {
      test('populates importableWorkouts and clears selection', () async {
        service.workouts = [makeWorkout('w1'), makeWorkout('w2')];
        await controller.loadImportableWorkouts();

        expect(controller.state.importableWorkouts, hasLength(2));
        expect(controller.state.selectedSourceIds, isEmpty);
        expect(controller.state.isLoadingWorkouts, isFalse);
      });

      test('copies route-consent guidance count from service', () async {
        service.routeConsentDeniedCountValue = 3;
        service.workouts = [makeWorkout('w1', hasRoute: false)];

        await controller.loadImportableWorkouts();

        expect(controller.state.routeConsentDeniedCount, 3);
      });

      test('shows loading flag then clears it', () async {
        final states = <bool>[];
        controller.addListener(
          () => states.add(controller.state.isLoadingWorkouts),
        );

        service.workouts = [makeWorkout('w1')];
        await controller.loadImportableWorkouts();

        expect(states, contains(true));
        expect(controller.state.isLoadingWorkouts, isFalse);
      });

      test('stores error and clears loading flag on failure', () async {
        service.nextError = const AppException(AppErrorCode.healthReadFailed);
        await controller.loadImportableWorkouts();

        expect(controller.state.isLoadingWorkouts, isFalse);
        expect(controller.state.error!.code, AppErrorCode.healthReadFailed);
      });

      test('returns to authorization when reading health data fails', () async {
        service.authStatus = HealthAuthorizationStatus.granted;
        await controller.loadStatus();
        service.nextError = const AppException(AppErrorCode.healthReadFailed);

        await controller.loadImportableWorkouts();

        expect(
          controller.state.authStatus,
          HealthAuthorizationStatus.notDetermined,
        );
      });
    });

    // ── Selection ───────────────────────────────────────────────────────────

    group('toggleSelection', () {
      test('adds a route-bearing workout to the selection', () async {
        service.workouts = [makeWorkout('w1')];
        await controller.loadImportableWorkouts();

        controller.toggleSelection('w1');
        expect(controller.state.selectedSourceIds, contains('w1'));
      });

      test('removes a workout that is already selected', () async {
        service.workouts = [makeWorkout('w1')];
        await controller.loadImportableWorkouts();

        controller.toggleSelection('w1');
        controller.toggleSelection('w1');
        expect(controller.state.selectedSourceIds, isNot(contains('w1')));
      });

      test('ignores non-importable (no-route) workouts', () async {
        service.workouts = [makeWorkout('w1', hasRoute: false)];
        await controller.loadImportableWorkouts();

        controller.toggleSelection('w1');
        expect(controller.state.selectedSourceIds, isEmpty);
      });
    });

    group('selectAll / clearSelection', () {
      test('selectAll selects all route-bearing workouts', () async {
        service.workouts = [
          makeWorkout('w1'),
          makeWorkout('w2'),
          makeWorkout('w3', hasRoute: false),
        ];
        await controller.loadImportableWorkouts();

        controller.selectAll();
        expect(controller.state.selectedSourceIds, containsAll(['w1', 'w2']));
        expect(controller.state.selectedSourceIds, isNot(contains('w3')));
      });

      test('clearSelection empties the selection', () async {
        service.workouts = [makeWorkout('w1'), makeWorkout('w2')];
        await controller.loadImportableWorkouts();

        controller.selectAll();
        controller.clearSelection();
        expect(controller.state.selectedSourceIds, isEmpty);
      });
    });

    // ── importSelected ──────────────────────────────────────────────────────

    group('importSelected', () {
      test('imports selected workouts and refreshes candidates', () async {
        service.workouts = [makeWorkout('w1'), makeWorkout('w2')];
        await controller.loadImportableWorkouts();
        controller.toggleSelection('w1');

        await controller.importSelected();

        expect(controller.state.importedCount, 1);
        expect(controller.state.isImporting, isFalse);
        expect(controller.state.selectedSourceIds, isEmpty);
        // w2 should still be in the list
        expect(
          controller.state.importableWorkouts.map((w) => w.sourceId),
          contains('w2'),
        );
      });

      test('no-op when nothing is selected', () async {
        await controller.importSelected();
        expect(service.importWorkoutsCallCount, 0);
      });

      test(
        'stores error on failure without losing isImporting=false',
        () async {
          service.workouts = [makeWorkout('w1')];
          await controller.loadImportableWorkouts();
          controller.toggleSelection('w1');
          service.nextError = const AppException(
            AppErrorCode.healthImportFailed,
          );

          await controller.importSelected();

          expect(controller.state.isImporting, isFalse);
          expect(controller.state.error!.code, AppErrorCode.healthImportFailed);
        },
      );
    });
  });
}
