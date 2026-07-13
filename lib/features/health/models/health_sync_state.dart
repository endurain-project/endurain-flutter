import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';

/// Sentinel used to distinguish "not provided" from an explicit `null` in
/// [HealthSyncState.copyWith].
const Object _unset = Object();

enum HealthSyncView { available, imported }

/// Immutable controller-facing snapshot of the health sync feature state.
///
/// Used by the health sync controller to expose the current state to the UI
/// without exposing mutable internals.
class HealthSyncState {
  const HealthSyncState({
    this.sdkStatus = HealthSdkStatus.unsupported,
    this.authStatus = HealthAuthorizationStatus.notDetermined,
    this.accessDetails = const HealthDataAccessDetails.systemManaged(),
    this.isCheckingStatus = true,
    this.isLoadingWorkouts = false,
    this.isImporting = false,
    this.importableWorkouts = const [],
    this.importedWorkouts = const [],
    this.selectedSourceIds = const {},
    this.selectedRange = HealthImportRange.defaultRange,
    this.selectedView = HealthSyncView.available,
    this.availableHasMore = false,
    this.importedHasMore = false,
    this.isLoadingMoreAvailable = false,
    this.isLoadingImported = false,
    this.isUpdatingAutoSync = false,
    this.autoSyncOnResume = false,
    this.lastSyncAt,
    this.importedCount = 0,
    this.failedImportCount = 0,
    this.routeConsentDeniedCount = 0,
    this.error,
  });

  /// Current availability of the health platform SDK.
  final HealthSdkStatus sdkStatus;

  /// Current authorization status for health data access.
  final HealthAuthorizationStatus authStatus;

  /// Platform-aware detail for Endurain's requested health data categories.
  final HealthDataAccessDetails accessDetails;

  /// `true` while platform availability and authorization are being checked.
  final bool isCheckingStatus;

  /// `true` while the importable workout list is being fetched.
  final bool isLoadingWorkouts;

  /// `true` while a selective import is in progress.
  final bool isImporting;

  /// Workouts available to import (route-bearing, not yet imported).
  ///
  /// Non-route workouts may also appear here but will have
  /// [HealthWorkout.hasRoute] == `false`, meaning they cannot be selected.
  final List<HealthWorkout> importableWorkouts;
  final List<HealthImportedWorkout> importedWorkouts;

  /// Source IDs the user has selected for the next import.
  ///
  /// Only route-bearing workout IDs should appear here; selection mutators
  /// must guard against non-importable entries.
  final Set<String> selectedSourceIds;
  final HealthImportRange selectedRange;
  final HealthSyncView selectedView;
  final bool availableHasMore;
  final bool importedHasMore;
  final bool isLoadingMoreAvailable;
  final bool isLoadingImported;
  final bool isUpdatingAutoSync;

  /// Whether new workouts are imported automatically when the app resumes.
  final bool autoSyncOnResume;

  /// UTC timestamp of the last successful import, or `null` if never synced.
  final DateTime? lastSyncAt;

  /// Number of workouts imported in the most recent import run.
  final int importedCount;

  /// Number of selected workouts that could not be persisted in the latest
  /// import run. A non-zero value means the user must review the result.
  final int failedImportCount;

  /// Number of workouts skipped because exercise-route consent was not granted
  /// for the source app in Health Connect (Android).
  ///
  /// When > 0 the UI should surface guidance: open Health Connect → Permissions
  /// → app → "Always allow" for exercise routes.
  final int routeConsentDeniedCount;

  /// The last error from an async operation, or `null` when idle / succeeded.
  final AppException? error;

  /// Returns a copy with the given fields replaced.
  HealthSyncState copyWith({
    HealthSdkStatus? sdkStatus,
    HealthAuthorizationStatus? authStatus,
    HealthDataAccessDetails? accessDetails,
    bool? isCheckingStatus,
    bool? isLoadingWorkouts,
    bool? isImporting,
    List<HealthWorkout>? importableWorkouts,
    List<HealthImportedWorkout>? importedWorkouts,
    Set<String>? selectedSourceIds,
    HealthImportRange? selectedRange,
    HealthSyncView? selectedView,
    bool? availableHasMore,
    bool? importedHasMore,
    bool? isLoadingMoreAvailable,
    bool? isLoadingImported,
    bool? isUpdatingAutoSync,
    bool? autoSyncOnResume,
    Object? lastSyncAt = _unset,
    int? importedCount,
    int? failedImportCount,
    int? routeConsentDeniedCount,
    Object? error = _unset,
  }) {
    return HealthSyncState(
      sdkStatus: sdkStatus ?? this.sdkStatus,
      authStatus: authStatus ?? this.authStatus,
      accessDetails: accessDetails ?? this.accessDetails,
      isCheckingStatus: isCheckingStatus ?? this.isCheckingStatus,
      isLoadingWorkouts: isLoadingWorkouts ?? this.isLoadingWorkouts,
      isImporting: isImporting ?? this.isImporting,
      importableWorkouts: importableWorkouts ?? this.importableWorkouts,
      importedWorkouts: importedWorkouts ?? this.importedWorkouts,
      selectedSourceIds: selectedSourceIds ?? this.selectedSourceIds,
      selectedRange: selectedRange ?? this.selectedRange,
      selectedView: selectedView ?? this.selectedView,
      availableHasMore: availableHasMore ?? this.availableHasMore,
      importedHasMore: importedHasMore ?? this.importedHasMore,
      isLoadingMoreAvailable:
          isLoadingMoreAvailable ?? this.isLoadingMoreAvailable,
      isLoadingImported: isLoadingImported ?? this.isLoadingImported,
      isUpdatingAutoSync: isUpdatingAutoSync ?? this.isUpdatingAutoSync,
      autoSyncOnResume: autoSyncOnResume ?? this.autoSyncOnResume,
      lastSyncAt: lastSyncAt == _unset
          ? this.lastSyncAt
          : lastSyncAt as DateTime?,
      importedCount: importedCount ?? this.importedCount,
      failedImportCount: failedImportCount ?? this.failedImportCount,
      routeConsentDeniedCount:
          routeConsentDeniedCount ?? this.routeConsentDeniedCount,
      error: error == _unset ? this.error : error as AppException?,
    );
  }
}
