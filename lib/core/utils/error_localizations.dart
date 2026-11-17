import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/l10n/app_localizations.dart';

String localizedErrorMessage(Object error, AppLocalizations l10n) {
  if (error is AppException) {
    return _localizedAppException(error, l10n);
  }

  final message = error.toString();
  const exceptionPrefix = 'Exception: ';
  if (message.startsWith(exceptionPrefix)) {
    return message.substring(exceptionPrefix.length);
  }

  return message;
}

String _localizedAppException(AppException error, AppLocalizations l10n) {
  final details = error.details;

  return switch (error.code) {
    AppErrorCode.activeActivityStoreReadFailed =>
      l10n.errorActivityLocalLoadFailed,
    AppErrorCode.activeActivityStoreWriteFailed =>
      l10n.errorActivityLocalSaveFailed,
    AppErrorCode.activityGpxCleanupFailed => l10n.errorActivityGpxCleanupFailed,
    AppErrorCode.activityGpxFileWriteFailed =>
      l10n.errorActivityGpxFileWriteFailed,
    AppErrorCode.activityLocalActivityNotFound =>
      l10n.errorActivityLocalActivityNotFound,
    AppErrorCode.activityLocalDeleteFailed =>
      l10n.errorActivityLocalDeleteFailed,
    AppErrorCode.activityLocalGpxMissing => l10n.errorActivityLocalGpxMissing,
    AppErrorCode.activityLocalLoadFailed => l10n.errorActivityLocalLoadFailed,
    AppErrorCode.activityLocalRecordInvalid =>
      l10n.errorActivityLocalRecordInvalid,
    AppErrorCode.activityLocalSaveFailed => l10n.errorActivityLocalSaveFailed,
    AppErrorCode.activityUploadFailed => switch (details) {
      null => l10n.errorActivityUploadFailed,
      // Ingestion job `error_code` values, reported by the server on a
      // failed upload.
      'unsupported_format' => l10n.errorActivityIngestionUnsupportedFormat,
      'invalid_file' => l10n.errorActivityIngestionInvalidFile,
      'no_activities_found' => l10n.errorActivityIngestionNoActivitiesFound,
      'processing_failed' => l10n.errorActivityIngestionProcessingFailed,
      'provider_unavailable' => l10n.errorActivityIngestionProviderUnavailable,
      // Set by the upload service for a `409` at the server's cap on open
      // uploads; the upload is retried later.
      'upload_limit' => l10n.errorActivityUploadLimit,
      _ => l10n.errorActivityUploadFailedWithDetails(details),
    },
    AppErrorCode.activityUploadNotConfigured =>
      l10n.errorActivityUploadNotConfigured,
    AppErrorCode.fetchProvidersFailed =>
      details == null
          ? l10n.errorFetchProvidersFailed
          : l10n.errorFetchProvidersFailedWithDetails(details),
    AppErrorCode.fetchServerSettingsFailed =>
      details == null
          ? l10n.errorFetchServerSettingsFailed
          : l10n.errorFetchServerSettingsFailedWithDetails(details),
    AppErrorCode.healthGpxBuildFailed => l10n.errorHealthGpxBuildFailed,
    AppErrorCode.healthImportFailed =>
      details == null
          ? l10n.errorHealthImportFailed
          : l10n.errorHealthImportFailedWithDetails(details),
    AppErrorCode.healthPermissionDenied => l10n.errorHealthPermissionDenied,
    AppErrorCode.healthReadFailed => l10n.errorHealthReadFailed,
    AppErrorCode.insecureRedirectRejected => l10n.errorInsecureRedirectRejected,
    AppErrorCode.insecureTransportNotAllowed =>
      l10n.errorInsecureTransportNotAllowed,
    AppErrorCode.invalidTileServerUrl => l10n.invalidUrl,
    AppErrorCode.loginError =>
      details == null
          ? l10n.errorLoginError
          : l10n.errorLoginErrorWithDetails(details),
    AppErrorCode.loginFailed =>
      details == null
          ? l10n.errorLoginFailed
          : l10n.errorLoginFailedWithDetails(details),
    AppErrorCode.mfaSessionMissing => l10n.errorMfaSessionMissing,
    AppErrorCode.mfaVerificationError =>
      details == null
          ? l10n.errorMfaVerificationError
          : l10n.errorMfaVerificationErrorWithDetails(details),
    AppErrorCode.mfaVerificationFailed =>
      details == null
          ? l10n.errorMfaVerificationFailed
          : l10n.errorMfaVerificationFailedWithDetails(details),
    AppErrorCode.noSessionIdReceived => l10n.errorNoSessionIdReceived,
    AppErrorCode.notAuthenticated => l10n.errorNotAuthenticated,
    AppErrorCode.passwordChangeFailed =>
      details == null
          ? l10n.errorPasswordChangeFailed
          : l10n.errorPasswordChangeFailedWithDetails(details),
    AppErrorCode.pkceVerifierMissingRestartLogin =>
      l10n.errorPkceVerifierMissingRestartLogin,
    AppErrorCode.requestTimeout => l10n.errorRequestTimeout,
    AppErrorCode.secureStorageDeleteFailed =>
      l10n.errorSecureStorageDeleteFailed,
    AppErrorCode.secureStorageReadFailed => l10n.errorSecureStorageReadFailed,
    AppErrorCode.secureStorageWriteFailed => l10n.errorSecureStorageWriteFailed,
    AppErrorCode.serverUrlNotConfigured => l10n.errorServerUrlNotConfigured,
    AppErrorCode.sessionExpired => l10n.errorSessionExpired,
    AppErrorCode.signInStepUnsupported => l10n.errorSignInStepUnsupported,
    // Only the server's documented codes reach [details]; anything else in
    // the deep link was dropped, since any app can fire it.
    AppErrorCode.ssoCallbackFailed => switch (details) {
      'sso_email_missing' => l10n.errorSsoEmailMissing,
      'sso_email_unverified' => l10n.errorSsoEmailUnverified,
      'sso_auto_create_disabled' => l10n.errorSsoAutoCreateDisabled,
      'sso_link_by_email_disabled' => l10n.errorSsoLinkByEmailDisabled,
      'sso_approval_pending' => l10n.errorSsoApprovalPending,
      'sso_account_disabled' => l10n.errorSsoAccountDisabled,
      _ => l10n.errorSsoCallbackFailed,
    },
    AppErrorCode.ssoRedirectNotAllowed => l10n.errorSsoRedirectNotAllowed,
    AppErrorCode.ssoTokenExchangeError =>
      details == null
          ? l10n.errorSsoTokenExchangeError
          : l10n.errorSsoTokenExchangeErrorWithDetails(details),
    AppErrorCode.tokenExchangeFailed =>
      details == null
          ? l10n.errorTokenExchangeFailed
          : l10n.errorTokenExchangeFailedWithDetails(details),
    AppErrorCode.tooManyRedirects => l10n.errorTooManyRedirects,
    // Reuses the timeout copy: to the user this is the same "temporarily
    // unavailable, try again" situation. The distinct code exists so internal
    // retry logic can recognize a transient auth-refresh failure.
    AppErrorCode.transientAuthUnavailable => l10n.errorRequestTimeout,
    AppErrorCode.unexpectedResponseFormat => l10n.errorUnexpectedResponseFormat,
    AppErrorCode.unsupportedHttpMethod =>
      details == null
          ? l10n.errorUnsupportedHttpMethod
          : l10n.errorUnsupportedHttpMethodWithDetails(details),
  };
}
