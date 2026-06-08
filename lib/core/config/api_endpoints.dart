import 'package:endurain/core/config/app_config.dart';

/// Builds API endpoint paths from [AppConfig.apiBasePath].
///
/// All path getters replace the hard-coded `/api/v1` prefix with
/// [AppConfig.apiBasePath], so a future API version bump or multi-environment
/// deployment only requires changing [AppConfig.apiBasePath] in one place.
///
/// Header names, timeouts, and multipart field names remain in
/// `ApiConstants`.
class ApiEndpoints {
  const ApiEndpoints([this._config = AppConfig.defaults]);

  final AppConfig _config;

  String get _base => _config.apiBasePath;

  // Authentication endpoints
  String get tokenEndpoint => '$_base/auth/login';
  String get mfaVerifyEndpoint => '$_base/auth/mfa/verify';
  String get refreshEndpoint => '$_base/auth/refresh';
  String get logoutEndpoint => '$_base/auth/logout';

  // SSO/OAuth endpoints
  String get idpListEndpoint => '$_base/public/idp';
  String get idpLoginEndpoint => '$_base/public/idp/login';
  String get idpSessionTokenExchangeEndpoint => '$_base/public/idp/session';

  // Server settings public endpoint
  String get serverSettingsEndpoint => '$_base/public/server_settings';

  // Activity endpoints
  String get activityUploadEndpoint => '$_base/activities/create/upload';
}
