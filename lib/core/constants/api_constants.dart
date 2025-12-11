/// API endpoint constants
class ApiConstants {
  // Authentication endpoints
  static const String tokenEndpoint = '/api/v1/token';
  static const String mfaVerifyEndpoint = '/api/v1/mfa/verify';
  static const String refreshEndpoint = '/api/v1/refresh';

  // Headers
  static const String clientTypeHeader = 'X-Client-Type';
  static const String clientTypeValue = 'mobile';
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormUrlEncoded =
      'application/x-www-form-urlencoded';
}
