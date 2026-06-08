/// API endpoint constants
class ApiConstants {
  // Headers
  static const String clientTypeHeader = 'X-Client-Type';
  static const String clientTypeValue = 'mobile';
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormUrlEncoded =
      'application/x-www-form-urlencoded';

  // Request timeouts
  static const Duration defaultRequestTimeout = Duration(seconds: 30);
  static const Duration defaultUploadTimeout = Duration(seconds: 120);

  // Authentication endpoints
  static const String tokenEndpoint = '/api/v1/auth/login';
  static const String mfaVerifyEndpoint = '/api/v1/auth/mfa/verify';
  static const String refreshEndpoint = '/api/v1/auth/refresh';
  static const String logoutEndpoint = '/api/v1/auth/logout';
  // SSO/OAuth endpoints
  static const String idpListEndpoint = '/api/v1/public/idp';
  static const String idpLoginEndpoint = '/api/v1/public/idp/login';
  static const String idpSessionTokenExchangeEndpoint =
      '/api/v1/public/idp/session';

  // Server settings public endpoints
  static const String serverSettingsEndpoint = '/api/v1/public/server_settings';

  // Activity endpoints
  static const String activityUploadEndpoint =
      '/api/v1/activities/create/upload';
  static const String activityUploadFieldName = 'file';
}
