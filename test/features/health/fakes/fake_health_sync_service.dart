import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_page.dart';
import 'package:endurain/features/health/services/health_sync_service.dart';

/// In-memory fake [HealthSyncService] for controller tests.
class FakeHealthSyncService implements HealthSyncService {
  HealthSdkStatus sdkStatus;
  HealthAuthorizationStatus authStatus;
  List<HealthWorkout> workouts;
  int routeConsentDeniedCountValue;
  bool autoSyncOnResumeEnabled = false;
  HealthDataAccessDetails accessDetailsValue;
  DateTime? lastSyncAtValue;
  List<HealthImportedWorkout> importedWorkouts = const [];
  bool availableHasMore = false;
  bool importedHasMore = false;

  int listImportableCallCount = 0;
  int importWorkoutsCallCount = 0;
  int importAllCallCount = 0;
  int installHealthConnectCallCount = 0;
  int requestAccessCallCount = 0;
  int disconnectCallCount = 0;
  int loadAvailableCallCount = 0;
  int loadMoreAvailableCallCount = 0;
  int listImportedCallCount = 0;
  int restoreMissingImportCallCount = 0;
  int clearDiscoveryCacheCallCount = 0;
  HealthImportRange? lastRange;

  /// Set to an [AppException] to make the next call throw.
  AppException? nextError;

  FakeHealthSyncService({
    this.sdkStatus = HealthSdkStatus.available,
    this.authStatus = HealthAuthorizationStatus.notDetermined,
    this.workouts = const [],
    this.routeConsentDeniedCountValue = 0,
    this.accessDetailsValue = const HealthDataAccessDetails.systemManaged(),
  });

  @override
  int get routeConsentDeniedCount => routeConsentDeniedCountValue;

  @override
  Future<HealthSdkStatus> status() async {
    _maybeThrow();
    return sdkStatus;
  }

  @override
  Future<HealthAuthorizationStatus> currentAuthorizationStatus() async {
    _maybeThrow();
    return authStatus;
  }

  @override
  Future<HealthDataAccessDetails> accessDetails() async {
    _maybeThrow();
    return accessDetailsValue;
  }

  @override
  Future<HealthAuthorizationStatus> requestAccess() async {
    _maybeThrow();
    requestAccessCallCount++;
    return authStatus;
  }

  @override
  Future<void> installHealthConnect() async {
    _maybeThrow();
    installHealthConnectCallCount++;
  }

  @override
  Future<List<HealthWorkout>> listImportable() async {
    _maybeThrow();
    listImportableCallCount++;
    return List.of(workouts);
  }

  @override
  Future<HealthWorkoutPage> loadAvailable({
    HealthImportRange range = HealthImportRange.defaultRange,
  }) async {
    _maybeThrow();
    loadAvailableCallCount++;
    listImportableCallCount++;
    lastRange = range;
    return HealthWorkoutPage(
      items: List.of(workouts),
      hasMore: availableHasMore,
    );
  }

  @override
  Future<HealthWorkoutPage> loadMoreAvailable() async {
    _maybeThrow();
    loadMoreAvailableCallCount++;
    return HealthWorkoutPage(items: List.of(workouts), hasMore: false);
  }

  @override
  Future<HealthImportedWorkoutPage> listImported({
    int offset = 0,
    int limit = 20,
  }) async {
    _maybeThrow();
    listImportedCallCount++;
    return HealthImportedWorkoutPage(
      items: importedWorkouts.skip(offset).take(limit).toList(),
      hasMore: importedHasMore,
    );
  }

  @override
  Future<void> restoreMissingImport(HealthImportedWorkout imported) async {
    _maybeThrow();
    restoreMissingImportCallCount++;
    importedWorkouts = importedWorkouts
        .where((entry) => entry.sourceId != imported.sourceId)
        .toList();
  }

  @override
  Future<({int failed, int imported})> importWorkouts(
    Iterable<String> sourceIds,
  ) async {
    _maybeThrow();
    importWorkoutsCallCount++;
    final ids = sourceIds.toSet();
    final imported = workouts
        .where((w) => ids.contains(w.sourceId) && w.hasRoute)
        .length;
    workouts = workouts.where((w) => !ids.contains(w.sourceId)).toList();
    return (imported: imported, failed: 0);
  }

  @override
  Future<({int failed, int imported})> importAll() async {
    _maybeThrow();
    importAllCallCount++;
    final imported = workouts.where((w) => w.hasRoute).length;
    workouts = workouts.where((w) => !w.hasRoute).toList();
    return (imported: imported, failed: 0);
  }

  @override
  Future<bool> isAutoSyncOnResumeEnabled() async => autoSyncOnResumeEnabled;

  @override
  Future<void> setAutoSyncOnResumeEnabled(bool enabled) async {
    autoSyncOnResumeEnabled = enabled;
  }

  @override
  Future<void> disconnect() async {
    _maybeThrow();
    disconnectCallCount++;
    authStatus = HealthAuthorizationStatus.notDetermined;
    autoSyncOnResumeEnabled = false;
  }

  @override
  Future<void> clearDiscoveryCache() async {
    clearDiscoveryCacheCallCount++;
  }

  @override
  Future<DateTime?> lastSyncAt() async => lastSyncAtValue;

  void _maybeThrow() {
    if (nextError != null) {
      final e = nextError!;
      nextError = null;
      throw e;
    }
  }

  // ── Not used in controller tests ──────────────────────────────────────────
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
