import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:health/health.dart';

/// Maps a read failure to an [AppException].
///
/// A missing permission becomes [AppErrorCode.healthPermissionDenied], the
/// only failure that means access was lost. Anything else is
/// [AppErrorCode.healthReadFailed], flagged as transient when the plugin
/// reports it as retryable (rate limit, Health Connect busy, iOS device
/// locked).
AppException healthReadFailed(Object error) {
  if (error is HealthException &&
      error.errorCode == HealthErrorCode.permissionDenied) {
    return AppException(AppErrorCode.healthPermissionDenied, cause: error);
  }
  return AppException(
    AppErrorCode.healthReadFailed,
    cause: error,
    isTransient: error is HealthException && error.isRetryable,
  );
}

/// Whether [error] says the health platform itself is missing or
/// unsupported, not that the user refused access.
///
/// The plugin reports Health Connect missing altogether as an
/// [UnsupportedError], and a data type the device cannot serve as
/// [HealthErrorCode.notSupported].
bool isHealthPlatformUnavailable(Object error) {
  return error is UnsupportedError ||
      (error is HealthException &&
          error.errorCode == HealthErrorCode.notSupported);
}

/// Maps the plugin's tri-state permission answer for one data type.
HealthDataAccessStatus healthAccessStatus(bool? granted) {
  return granted == true
      ? HealthDataAccessStatus.allowed
      : HealthDataAccessStatus.needsAttention;
}
