import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';

/// Abstract adapter for health platform access (HealthKit / Health Connect).
///
/// ## Contract
/// - All methods are async and return immediately when the platform is not
///   supported — they MUST NOT block the UI thread.
/// - Failures are surfaced as [AppException] with the appropriate
///   [AppErrorCode] (e.g. `healthReadFailed`, `healthPermissionDenied`).
///   Raw platform exceptions must be caught and wrapped.
/// - Implementations MUST NEVER log coordinates, device identifiers, or any
///   other personally-identifiable information. Diagnostic breadcrumbs should
///   contain only sanitised counts or error codes.
abstract class HealthPlatformAdapter {
  /// Number of workouts in the last read whose route data could not be read
  /// because route access was unavailable or denied.
  int get routeConsentDeniedCount;

  /// Returns the current availability of the health platform SDK.
  ///
  /// On platforms that do not support health sync (desktop, web) this returns
  /// [HealthSdkStatus.unsupported] without performing any native call.
  Future<HealthSdkStatus> getSdkStatus();

  /// Requests (or re-requests) authorization to read health data.
  ///
  /// Returns [HealthAuthorizationStatus.granted] when the user has granted
  /// the necessary permissions. Returns [HealthAuthorizationStatus.denied]
  /// when the user denies or has previously denied access.
  ///
  /// Throws [AppException] with [AppErrorCode.healthPermissionDenied] on a
  /// hard denial that the app cannot recover from.
  Future<HealthAuthorizationStatus> requestAuthorization();

  /// Returns the current authorization status without triggering a prompt.
  ///
  /// Use this to decide whether to show a "Connect" button or the import UI.
  Future<HealthAuthorizationStatus> currentAuthorizationStatus();

  /// Returns the per-category health-data access status when the platform
  /// allows it. HealthKit does not reveal read grants, so implementations must
  /// return a non-inspectable [HealthDataAccessDetails] on Apple platforms.
  Future<HealthDataAccessDetails> getAccessDetails();

  /// Directs the user to the platform app store to install the health
  /// provider (Google Health Connect on Android).
  ///
  /// No-op on platforms where the provider is built in or unavailable
  /// (iOS, desktop, web).
  Future<void> installHealthConnect();

  /// Revokes health permissions where the platform supports it.
  /// HealthKit is system-managed, so the iOS implementation is a no-op.
  Future<void> revokePermissions();

  /// Reads all workouts in the given time window from the health platform.
  ///
  /// [start] and [end] are inclusive UTC timestamps defining the lookback
  /// window. Returns an empty list when no workouts are found or when health
  /// sync is unavailable.
  ///
  /// Route data (GPS track points) is fetched and merged into each
  /// [HealthWorkout.route] where available. Workouts for which route consent
  /// has not been granted will have an empty [HealthWorkout.route].
  ///
  /// Throws [AppException] with [AppErrorCode.healthReadFailed] on a
  /// non-recoverable read failure.
  Future<List<HealthWorkout>> readWorkouts({
    required DateTime start,
    required DateTime end,
  });
}

/// [HealthPlatformAdapter] implementation for platforms where health sync is
/// not supported (desktop, web, test host runtime).
///
/// All methods return safe "off" values without making any native calls.
/// This is the graceful degradation path: GPS recording and manual upload
/// continue to work regardless of whether this adapter is active.
class UnsupportedHealthPlatformAdapter implements HealthPlatformAdapter {
  const UnsupportedHealthPlatformAdapter();

  @override
  int get routeConsentDeniedCount => 0;

  @override
  Future<HealthSdkStatus> getSdkStatus() async => HealthSdkStatus.unsupported;

  @override
  Future<HealthAuthorizationStatus> requestAuthorization() async =>
      HealthAuthorizationStatus.denied;

  @override
  Future<HealthAuthorizationStatus> currentAuthorizationStatus() async =>
      HealthAuthorizationStatus.denied;

  @override
  Future<HealthDataAccessDetails> getAccessDetails() async =>
      const HealthDataAccessDetails.systemManaged();

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<void> revokePermissions() async {}

  @override
  Future<List<HealthWorkout>> readWorkouts({
    required DateTime start,
    required DateTime end,
  }) async => const [];
}
