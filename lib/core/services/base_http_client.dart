import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_response.dart';

/// A thin wrapper around [http.Client] that provides standard unauthenticated
/// request helpers used by auth, SSO, and server-settings services.
///
/// Responsibilities:
/// - Merges the shared [ApiConstants.clientTypeHeader] into every request.
/// - Checks the HTTP status code and delegates JSON decoding to [ApiResponse].
/// - Throws [AppException] with a caller-supplied [AppErrorCode] on non-2xx
///   responses so callers never have to hand-roll the status/decode branch.
///
/// Network-level exceptions are intentionally NOT caught here — callers own
/// the outer try/catch and supply the appropriate typed error code for their
/// context (e.g. `loginError`, `ssoTokenExchangeError`).
///
/// Bearer-token refresh and injection belong in `ApiClient`, not here.
class BaseHttpClient {
  BaseHttpClient({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _defaultHeaders = {
    ApiConstants.clientTypeHeader: ApiConstants.clientTypeValue,
  };

  // ---------------------------------------------------------------------------
  // Low-level request methods (return the raw response for callers that need
  // full control over the response, e.g. logout which accepts any status).
  // ---------------------------------------------------------------------------

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? extraHeaders,
  }) {
    return _client.get(url, headers: _mergeHeaders(extraHeaders));
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? extraHeaders,
    Object? body,
  }) {
    return _client.post(
      url,
      headers: _mergeHeaders(extraHeaders),
      body: body,
    );
  }

  // ---------------------------------------------------------------------------
  // High-level helpers: check status, decode JSON, throw on failure.
  // ---------------------------------------------------------------------------

  /// Makes a GET request and returns the decoded JSON object.
  ///
  /// Throws [AppException] with [failureCode] when the server returns a
  /// non-200 status. Throws [AppException] with
  /// [AppErrorCode.unexpectedResponseFormat] when the body is not a JSON
  /// object. Network errors propagate unchanged.
  Future<Map<String, dynamic>> getJsonObject(
    Uri url, {
    Map<String, String>? extraHeaders,
    required AppErrorCode failureCode,
  }) async {
    final response = await get(url, extraHeaders: extraHeaders);
    if (response.statusCode == 200) {
      return ApiResponse.decodeJsonObject(response);
    }
    throw ApiResponse.failure(response, failureCode);
  }

  /// Makes a GET request and returns the decoded JSON value (object or list).
  ///
  /// Throws [AppException] with [failureCode] on non-200 responses.
  Future<Object?> getJson(
    Uri url, {
    Map<String, String>? extraHeaders,
    required AppErrorCode failureCode,
  }) async {
    final response = await get(url, extraHeaders: extraHeaders);
    if (response.statusCode == 200) {
      return ApiResponse.decodeJson(response);
    }
    throw ApiResponse.failure(response, failureCode);
  }

  /// Makes a POST request with a JSON body and returns the decoded JSON object.
  ///
  /// [body] is JSON-encoded automatically when it is a [Map]. Pass a
  /// pre-encoded [String] or form-encoded body via [rawBody] and set
  /// [extraHeaders] to the appropriate Content-Type if needed.
  ///
  /// Throws [AppException] with [failureCode] on non-200 responses.
  Future<Map<String, dynamic>> postJsonObject(
    Uri url, {
    Map<String, String>? extraHeaders,
    Map<String, dynamic>? jsonBody,
    Object? rawBody,
    required AppErrorCode failureCode,
  }) async {
    assert(
      jsonBody == null || rawBody == null,
      'Provide either jsonBody or rawBody, not both.',
    );
    final encodedBody = jsonBody != null ? jsonEncode(jsonBody) : rawBody;
    final headers = jsonBody != null
        ? {
            ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
            ...?extraHeaders,
          }
        : extraHeaders;
    final response = await post(url, extraHeaders: headers, body: encodedBody);
    if (response.statusCode == 200) {
      return ApiResponse.decodeJsonObject(response);
    }
    throw ApiResponse.failure(response, failureCode);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Map<String, String> _mergeHeaders(Map<String, String>? extra) {
    if (extra == null || extra.isEmpty) {
      return _defaultHeaders;
    }
    return {..._defaultHeaders, ...extra};
  }
}
