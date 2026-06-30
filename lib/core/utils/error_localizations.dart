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
    AppErrorCode.activityUploadFailed =>
      details == null
          ? l10n.errorActivityUploadFailed
          : l10n.errorActivityUploadFailedWithDetails(details),
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
    AppErrorCode.pkceVerifierMissingRestartLogin =>
      l10n.errorPkceVerifierMissingRestartLogin,
    AppErrorCode.requestTimeout => l10n.errorRequestTimeout,
    AppErrorCode.secureStorageDeleteFailed =>
      l10n.errorSecureStorageDeleteFailed,
    AppErrorCode.secureStorageReadFailed => l10n.errorSecureStorageReadFailed,
    AppErrorCode.secureStorageWriteFailed => l10n.errorSecureStorageWriteFailed,
    AppErrorCode.serverUrlNotConfigured => l10n.errorServerUrlNotConfigured,
    AppErrorCode.sessionExpired => l10n.errorSessionExpired,
    AppErrorCode.ssoTokenExchangeError =>
      details == null
          ? l10n.errorSsoTokenExchangeError
          : l10n.errorSsoTokenExchangeErrorWithDetails(details),
    AppErrorCode.tokenExchangeFailed =>
      details == null
          ? l10n.errorTokenExchangeFailed
          : l10n.errorTokenExchangeFailedWithDetails(details),
    AppErrorCode.unexpectedResponseFormat => l10n.errorUnexpectedResponseFormat,
    AppErrorCode.unsupportedHttpMethod =>
      details == null
          ? l10n.errorUnsupportedHttpMethod
          : l10n.errorUnsupportedHttpMethodWithDetails(details),
  };
}
