import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_sync_state.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';

void main() {
  final start = DateTime.utc(2025, 6, 1, 9, 0);
  final end = DateTime.utc(2025, 6, 1, 10, 0);

  HealthWorkout makeWorkout(String id) => HealthWorkout(
    sourceId: id,
    type: HealthWorkoutType.run,
    startedAt: start,
    endedAt: end,
    route: [
      HealthRoutePoint(
        latitude: 38.0,
        longitude: -9.0,
        time: DateTime.utc(2025, 6, 1, 9, 0),
      ),
    ],
  );

  group('HealthSyncState', () {
    test('default values', () {
      const state = HealthSyncState();
      expect(state.sdkStatus, HealthSdkStatus.unsupported);
      expect(state.authStatus, HealthAuthorizationStatus.notDetermined);
      expect(state.isLoadingWorkouts, isFalse);
      expect(state.isImporting, isFalse);
      expect(state.importableWorkouts, isEmpty);
      expect(state.selectedSourceIds, isEmpty);
      expect(state.lastSyncAt, isNull);
      expect(state.importedCount, 0);
      expect(state.routeConsentDeniedCount, 0);
      expect(state.error, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final state = HealthSyncState(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        importableWorkouts: [makeWorkout('a')],
        selectedSourceIds: const {'a'},
        lastSyncAt: DateTime.utc(2025, 6, 1),
        importedCount: 2,
        routeConsentDeniedCount: 1,
      );

      final copy = state.copyWith(isLoadingWorkouts: true);
      expect(copy.sdkStatus, HealthSdkStatus.available);
      expect(copy.authStatus, HealthAuthorizationStatus.granted);
      expect(copy.isLoadingWorkouts, isTrue);
      expect(copy.importableWorkouts, hasLength(1));
      expect(copy.selectedSourceIds, contains('a'));
      expect(copy.lastSyncAt, DateTime.utc(2025, 6, 1));
      expect(copy.importedCount, 2);
      expect(copy.routeConsentDeniedCount, 1);
    });

    test('copyWith can update selectedSourceIds', () {
      const state = HealthSyncState();
      final copy1 = state.copyWith(selectedSourceIds: {'w1', 'w2'});
      expect(copy1.selectedSourceIds, {'w1', 'w2'});

      final copy2 = copy1.copyWith(selectedSourceIds: {'w1'});
      expect(copy2.selectedSourceIds, {'w1'});

      final copy3 = copy2.copyWith(selectedSourceIds: {});
      expect(copy3.selectedSourceIds, isEmpty);
    });

    test('copyWith can clear lastSyncAt to null', () {
      final state = HealthSyncState(lastSyncAt: DateTime.utc(2025, 6, 1));
      final copy = state.copyWith(lastSyncAt: null);
      expect(copy.lastSyncAt, isNull);
    });

    test('copyWith can clear error to null', () {
      const state = HealthSyncState(
        error: AppException(AppErrorCode.activityUploadFailed),
      );
      final copy = state.copyWith(error: null);
      expect(copy.error, isNull);
    });
  });
}
