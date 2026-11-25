import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';

/// Configurable fake [HealthPlatformAdapter] for use in unit and widget tests.
///
/// All return values are programmable via the public fields. Call counts are
/// recorded so tests can assert that methods were (or were not) called.
class FakeHealthPlatformAdapter implements HealthPlatformAdapter {
  FakeHealthPlatformAdapter({
    this._sdkStatus = HealthSdkStatus.available,
    HealthAuthorizationStatus authStatus =
        HealthAuthorizationStatus.notDetermined,
    this.accessDetails = const HealthDataAccessDetails.systemManaged(),
    List<HealthWorkout>? workouts,
  }) : _authStatus = authStatus,
       _workouts = workouts ?? [];

  HealthSdkStatus _sdkStatus;
  HealthAuthorizationStatus _authStatus;
  List<HealthWorkout> _workouts;
  List<List<HealthWorkout>> workoutPages = const [];
  int _routeConsentDeniedCount = 0;

  /// Reported as [historyAccessDeclined] after a read whose start is before
  /// this time (mimics Health Connect without the history permission).
  DateTime? historyDeclinedBefore;
  bool _historyAccessDeclined = false;
  AppException? readWorkoutsError;
  Future<HealthAuthorizationStatus>? currentAuthorizationStatusFuture;
  HealthDataAccessDetails accessDetails;

  // Call counters
  int getSdkStatusCallCount = 0;
  int requestAuthorizationCallCount = 0;
  int currentAuthorizationStatusCallCount = 0;
  int readWorkoutsCallCount = 0;
  int installHealthConnectCallCount = 0;
  int revokePermissionsCallCount = 0;

  // Last arguments passed to readWorkouts
  DateTime? lastReadStart;

  /// Source ids the `exclude` callback of readWorkouts left out.
  final List<String> excludedSourceIds = [];
  DateTime? lastReadEnd;
  final List<({DateTime start, DateTime end})> readWindows = [];

  // Programmable setters
  set sdkStatus(HealthSdkStatus value) => _sdkStatus = value;
  set authStatus(HealthAuthorizationStatus value) => _authStatus = value;
  set workouts(List<HealthWorkout> value) => _workouts = value;
  set routeConsentDeniedCountValue(int value) =>
      _routeConsentDeniedCount = value;

  @override
  int get routeConsentDeniedCount => _routeConsentDeniedCount;

  @override
  bool get historyAccessDeclined => _historyAccessDeclined;

  @override
  Future<HealthSdkStatus> getSdkStatus() async {
    getSdkStatusCallCount++;
    return _sdkStatus;
  }

  @override
  Future<HealthAuthorizationStatus> requestAuthorization() async {
    requestAuthorizationCallCount++;
    return _authStatus;
  }

  @override
  Future<HealthAuthorizationStatus> currentAuthorizationStatus() async {
    currentAuthorizationStatusCallCount++;
    if (currentAuthorizationStatusFuture case final future?) {
      return future;
    }
    return _authStatus;
  }

  @override
  Future<HealthDataAccessDetails> getAccessDetails() async => accessDetails;

  @override
  Future<void> installHealthConnect() async {
    installHealthConnectCallCount++;
  }

  @override
  Future<void> revokePermissions() async {
    revokePermissionsCallCount++;
  }

  @override
  Future<List<HealthWorkout>> readWorkouts({
    required DateTime start,
    required DateTime end,
    Future<bool> Function(String sourceId)? exclude,
  }) async {
    readWorkoutsCallCount++;
    lastReadStart = start;
    lastReadEnd = end;
    readWindows.add((start: start, end: end));
    final declinedBefore = historyDeclinedBefore;
    _historyAccessDeclined =
        declinedBefore != null && start.isBefore(declinedBefore);
    if (readWorkoutsError case final error?) throw error;
    final List<HealthWorkout> page;
    if (workoutPages.isNotEmpty) {
      final index = (readWorkoutsCallCount - 1).clamp(
        0,
        workoutPages.length - 1,
      );
      page = workoutPages[index];
    } else {
      page = _workouts;
    }
    final result = <HealthWorkout>[];
    for (final workout in page) {
      if (exclude != null && await exclude(workout.sourceId)) {
        excludedSourceIds.add(workout.sourceId);
      } else {
        result.add(workout);
      }
    }
    return List.unmodifiable(result);
  }
}
