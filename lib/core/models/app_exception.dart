enum AppErrorCode {
  activeActivityStoreReadFailed,
  activeActivityStoreWriteFailed,
  activityGpxCleanupFailed,
  activityGpxFileWriteFailed,
  activityLocalActivityNotFound,
  activityLocalDeleteFailed,
  activityLocalGpxMissing,
  activityLocalLoadFailed,
  activityLocalRecordInvalid,
  activityLocalSaveFailed,
  activityUploadFailed,
  activityUploadNotConfigured,
  fetchProvidersFailed,
  fetchServerSettingsFailed,
  healthGpxBuildFailed,
  healthImportFailed,
  healthPermissionDenied,
  healthReadFailed,
  healthUnavailable,
  insecureTransportNotAllowed,
  invalidTileServerUrl,
  loginError,
  loginFailed,
  mfaVerificationError,
  mfaVerificationFailed,
  noSessionIdReceived,
  notAuthenticated,
  pkceVerifierMissingRestartLogin,
  requestTimeout,
  secureStorageDeleteFailed,
  secureStorageReadFailed,
  secureStorageWriteFailed,
  serverUrlNotConfigured,
  sessionExpired,
  ssoTokenExchangeError,
  tokenExchangeFailed,

  /// A token refresh could not be completed due to a transient network or
  /// server condition, but the stored session is still valid. Callers should
  /// treat this as retryable, unlike [sessionExpired], which is terminal.
  transientAuthUnavailable,
  unexpectedResponseFormat,
  unsupportedHttpMethod,
}

/// Single canonical lookup of [AppErrorCode] by its `name`, built once.
///
/// Use this instead of scanning `AppErrorCode.values` per call.
final Map<String, AppErrorCode> _appErrorCodesByName = {
  for (final code in AppErrorCode.values) code.name: code,
};

/// Returns the [AppErrorCode] whose `name` equals [value], or `null` when
/// [value] is null or does not match a known code.
AppErrorCode? appErrorCodeByName(Object? value) =>
    value is String ? _appErrorCodesByName[value] : null;

class AppException implements Exception {
  const AppException(this.code, {this.details, this.cause});

  final AppErrorCode code;
  final String? details;
  final Object? cause;

  @override
  String toString() {
    final parts = [
      code.name,
      if (details != null) details,
      if (cause != null) cause,
    ];
    return parts.join(': ');
  }
}
