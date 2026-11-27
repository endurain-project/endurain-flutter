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

  /// Shared instance for the default [AppConfig]. Tests and call sites that do
  /// not need a custom base path can reuse this instead of allocating one.
  static const ApiEndpoints defaults = ApiEndpoints();

  final AppConfig _config;

  String get _base => _config.apiBasePath;

  // Sign-in, session renewal and sign-out. Every answer of login, MFA
  // verification, password change and the token exchange carries a
  // `next_step` (see `SignInFlow`).
  String get tokenEndpoint => '$_base/auth/login';
  String get mfaVerifyEndpoint => '$_base/auth/mfa/verify';
  String get passwordChangeEndpoint => '$_base/auth/password-change';
  String get refreshEndpoint => '$_base/auth/refresh';
  String get logoutEndpoint => '$_base/auth/logout';

  /// PKCE exchange of a sign-in session, for password and SSO sign-ins alike.
  String sessionTokensEndpoint(String sessionId) =>
      '$_base/auth/sessions/${Uri.encodeComponent(sessionId)}/tokens';

  // SSO/OAuth endpoints
  String get idpListEndpoint => '$_base/public/idp';
  String get idpLoginEndpoint => '$_base/public/idp/login';

  /// The icon an administrator uploaded for the provider [slug].
  String idpIconEndpoint(String slug) =>
      '$_base/public/idp/${Uri.encodeComponent(slug)}/icon';

  // Authenticated profile endpoint.
  String get profileEndpoint => '$_base/profile';

  // Server settings public endpoint
  String get serverSettingsEndpoint => '$_base/public/server-settings';

  // Activity endpoints
  String get activityUploadEndpoint => '$_base/activities/upload';

  /// A background job, such as the one an upload starts (`202`).
  String jobEndpoint(String jobId) =>
      '$_base/jobs/${Uri.encodeComponent(jobId)}';

  /// Whether [path] is a job path on this API (the `Content-Location` a `202`
  /// names), so a server-supplied header can never steer the client's bearer
  /// token to another route.
  bool isJobPath(String path) {
    final prefix = '$_base/jobs/';
    if (!path.startsWith(prefix) || path.contains('?') || path.contains('#')) {
      return false;
    }
    final id = path.substring(prefix.length);
    return id.isNotEmpty && !id.contains('/') && !id.contains('..');
  }
}
