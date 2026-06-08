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
  invalidTileServerUrl,
  loginError,
  loginFailed,
  mfaVerificationError,
  mfaVerificationFailed,
  noSessionIdReceived,
  notAuthenticated,
  pkceVerifierMissing,
  pkceVerifierMissingRestartLogin,
  requestTimeout,
  secureStorageDeleteFailed,
  secureStorageReadFailed,
  secureStorageWriteFailed,
  serverUrlNotConfigured,
  sessionExpired,
  ssoTokenExchangeError,
  tokenExchangeFailed,
  unexpectedResponseFormat,
  unsupportedHttpMethod,
}

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
