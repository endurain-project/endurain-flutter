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

  /// Header used to make activity uploads idempotent. The client sends a stable
  /// key (the local activity id) that stays constant across retries of the same
  /// activity, so a server that honors it can de-duplicate repeated uploads
  /// caused by automatic retry. Servers that ignore it are unaffected.
  static const String idempotencyKeyHeader = 'Idempotency-Key';

  // Request timeouts
  static const Duration defaultRequestTimeout = Duration(seconds: 30);
  static const Duration defaultUploadTimeout = Duration(seconds: 120);

  /// Maximum redirect hops followed by `RedirectPolicyClient`. Matches the
  /// `dart:io` default so behaviour is unchanged for well-behaved servers.
  static const int maxRedirects = 5;

  // SSO PKCE flow TTL — flows older than this are rejected on exchange.
  static const Duration ssoPkceTtl = Duration(minutes: 10);

  // Multipart field name for activity uploads. Endpoint paths live in
  // ApiEndpoints, which derives them from AppConfig.apiBasePath.
  static const String activityUploadFieldName = 'file';
}
