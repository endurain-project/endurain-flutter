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

  /// The health platform is missing or unsupported (for example Health
  /// Connect is not installed), as opposed to access being denied.
  healthUnavailable,

  /// A redirect tried to downgrade an `https` request to plain `http`.
  /// Refused outright rather than followed, because it is the standard way to
  /// strip TLS before harvesting a credential.
  insecureRedirectRejected,
  insecureTransportNotAllowed,
  invalidTileServerUrl,
  loginError,
  loginFailed,
  mfaVerificationError,
  mfaSessionMissing,
  mfaVerificationFailed,
  noSessionIdReceived,
  notAuthenticated,

  /// The new password was refused at sign-in, usually by the password policy
  /// (the server's problem detail says why). The challenge stays valid.
  passwordChangeFailed,
  pkceVerifierMissingRestartLogin,
  requestTimeout,
  secureStorageDeleteFailed,
  secureStorageReadFailed,
  secureStorageWriteFailed,
  serverUrlNotConfigured,
  sessionExpired,

  /// The server answered a sign-in `next_step` this app version does not
  /// know. The sign-in is abandoned and the user is told to update the app.
  signInStepUnsupported,

  /// The SSO deep-link callback reported a failure. The server-supplied text is
  /// deliberately discarded: the link is attacker-controllable.
  ///
  /// [AppException.details] carries one of the server's documented SSO failure
  /// codes (`sso_email_missing`, …) when the link named one, so the message
  /// can say why without showing attacker-supplied text.
  ssoCallbackFailed,

  /// The server's `allowed_redirect_uris` does not list this app's SSO
  /// callback, so the provider sign-in could not return to the app.
  ssoRedirectNotAllowed,
  ssoTokenExchangeError,
  tokenExchangeFailed,

  /// A request exceeded the redirect budget, which usually means a redirect
  /// loop on the configured server.
  tooManyRedirects,

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
  const AppException(
    this.code, {
    this.details,
    this.cause,
    this.statusCode,
    this.isTransient = false,
    this.retryAfter,
  });

  final AppErrorCode code;
  final String? details;
  final Object? cause;

  /// HTTP status of the failed response, when the failure came from one.
  final int? statusCode;

  /// Whether the same call may succeed if retried later (a rate limit, a busy
  /// platform service, a locked device). Callers use it to avoid treating a
  /// passing failure as a lasting one, such as a lost authorization.
  final bool isTransient;

  /// How long the server asked the client to wait before retrying (its
  /// `Retry-After`), when the failed response carried one.
  final Duration? retryAfter;

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
