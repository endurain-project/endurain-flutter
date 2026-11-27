import 'dart:async';
import 'dart:convert';

import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/network/api_response.dart';
import 'package:endurain/core/network/base_http_client.dart';
import 'package:endurain/core/network/http_diagnostics.dart';
import 'package:endurain/core/services/platform/multipart_upload_adapter.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:http/http.dart' as http;

/// Authenticated API surface for the Endurain server.
///
/// Wraps an unauthenticated [BaseHttpClient] with the bearer-token concerns:
/// it resolves the active session's server origin, attaches a valid access
/// token, proactively refreshes a token that is about to expire, and
/// transparently refreshes-and-retries once on a `401`. Every request is scoped
/// to the expected connection profile so a response can never be applied to the
/// wrong account after a session change.
///
/// Two request families share this machinery:
/// - authenticated JSON verbs ([getJsonObject], [getJson], [postJsonObject])
///   for the server-sync endpoints, and
/// - multipart [uploadFile] for activity GPX uploads.
///
/// The unauthenticated auth/SSO/server-settings calls that first establish a
/// session use [BaseHttpClient] directly instead.
class ApiClient {
  ApiClient({
    SecureStorageService? storage,
    AuthSessionStore? sessionStore,
    AuthService? authService,
    BaseHttpClient? baseClient,
    MultipartUploadAdapter? uploadAdapter,
    Duration? uploadTimeout,
    AppConfig config = AppConfig.defaults,
    DiagnosticsRecorder? diagnostics,
  }) : _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder() {
    final resolvedStore =
        sessionStore ??
        AuthSessionStore(
          storage: storage ?? SecureStorageService(),
          config: config,
        );
    _sessionStore = resolvedStore;
    _authService =
        authService ??
        AuthService(sessionStore: resolvedStore, storage: storage);
    _baseClient = baseClient ?? BaseHttpClient(diagnostics: _diagnostics);
    _uploadTimeout = uploadTimeout ?? ApiConstants.defaultUploadTimeout;
    _uploadAdapter = uploadAdapter ?? HttpMultipartUploadAdapter();
    _config = config;
  }

  late final AuthSessionStore _sessionStore;
  late final AuthService _authService;
  late final BaseHttpClient _baseClient;
  late final MultipartUploadAdapter _uploadAdapter;
  late final Duration _uploadTimeout;
  late final AppConfig _config;
  final DiagnosticsRecorder _diagnostics;

  /// Upload a file with multipart/form-data
  ///
  /// When [idempotencyKey] is provided it is sent as the
  /// [ApiConstants.idempotencyKeyHeader] so a server that honors it can
  /// de-duplicate retried uploads of the same activity.
  ///
  /// A final `4xx`/`5xx` answer or a transport error is recorded to
  /// diagnostics, as `BaseHttpClient` does for the JSON verbs.
  Future<http.StreamedResponse> uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    String? idempotencyKey,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    final stopwatch = Stopwatch()..start();
    // Only the path matters: the template drops the host.
    final url = Uri.parse(endpoint);
    try {
      final response = await _uploadFile(
        endpoint,
        filePath,
        fieldName,
        idempotencyKey: idempotencyKey,
        expectedOrigin: expectedOrigin,
        expectedProfileId: expectedProfileId,
      );
      if (response.statusCode >= 400) {
        recordHttpFailure(
          _diagnostics,
          method: 'POST',
          url: url,
          elapsed: stopwatch.elapsed,
          status: response.statusCode,
        );
      }
      return response;
    } catch (error) {
      recordHttpFailure(
        _diagnostics,
        method: 'POST',
        url: url,
        elapsed: stopwatch.elapsed,
        error: error,
      );
      rethrow;
    }
  }

  Future<http.StreamedResponse> _uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    String? idempotencyKey,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    final session = await _getValidSession(
      expectedOrigin: expectedOrigin,
      expectedProfileId: expectedProfileId,
    );
    final serverUrl = ServerUrlResolver.normalize(
      session.origin,
      config: _config,
    );

    final url = Uri.parse('$serverUrl$endpoint');
    final headers = {
      ApiConstants.authorizationHeader: 'Bearer ${session.accessToken}',
      ApiConstants.clientTypeHeader: ApiConstants.clientTypeValue,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        ApiConstants.idempotencyKeyHeader: idempotencyKey,
    };

    Future<http.StreamedResponse> upload() => _uploadAdapter
        .uploadFile(
          url: url,
          headers: headers,
          filePath: filePath,
          fieldName: fieldName,
        )
        .timeout(
          _uploadTimeout,
          onTimeout: () =>
              throw const AppException(AppErrorCode.requestTimeout),
        );

    http.StreamedResponse response = await upload();

    if (response.statusCode == 401) {
      await response.stream.drain<void>();
      final refreshedSession = await _refreshSessionAfter401(
        serverUrl: serverUrl,
        expectedOrigin: expectedOrigin,
        expectedProfileId: expectedProfileId,
      );
      headers[ApiConstants.authorizationHeader] =
          'Bearer ${refreshedSession.accessToken}';
      response = await upload();
    }

    return response;
  }

  // ── Authenticated JSON verbs ─────────────────────────────────────────────

  /// Sends an authenticated `GET` and returns the decoded JSON object.
  ///
  /// Throws [AppException] with [failureCode] on a non-200 response.
  Future<Map<String, dynamic>> getJsonObject(
    String endpoint, {
    required AppErrorCode failureCode,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    return _sendAndDecode(
      'GET',
      endpoint,
      failureCode: failureCode,
      decode: ApiResponse.decodeJsonObject,
      expectedOrigin: expectedOrigin,
      expectedProfileId: expectedProfileId,
    );
  }

  /// Sends an authenticated `GET` and returns the decoded JSON object with the
  /// response headers (lower-cased names), for reads whose headers matter,
  /// such as the `Retry-After` of a job.
  ///
  /// Throws [AppException] with [failureCode] on a non-200 response.
  Future<({Map<String, dynamic> body, Map<String, String> headers})>
  getJsonObjectWithHeaders(
    String endpoint, {
    required AppErrorCode failureCode,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    return _sendAndDecode(
      'GET',
      endpoint,
      failureCode: failureCode,
      decode: (response) => (
        body: ApiResponse.decodeJsonObject(response),
        headers: response.headers,
      ),
      expectedOrigin: expectedOrigin,
      expectedProfileId: expectedProfileId,
    );
  }

  /// Sends an authenticated `GET` and returns the decoded JSON value (object or
  /// list).
  ///
  /// Throws [AppException] with [failureCode] on a non-200 response.
  Future<Object?> getJson(
    String endpoint, {
    required AppErrorCode failureCode,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    return _sendAndDecode(
      'GET',
      endpoint,
      failureCode: failureCode,
      decode: ApiResponse.decodeJson,
      expectedOrigin: expectedOrigin,
      expectedProfileId: expectedProfileId,
    );
  }

  /// Sends an authenticated `POST` with an optional JSON [body] and returns the
  /// decoded JSON object.
  Future<Map<String, dynamic>> postJsonObject(
    String endpoint, {
    Map<String, dynamic>? body,
    required AppErrorCode failureCode,
    String? expectedOrigin,
    String? expectedProfileId,
  }) => _sendJsonForObject(
    'POST',
    endpoint,
    body: body,
    failureCode: failureCode,
    expectedOrigin: expectedOrigin,
    expectedProfileId: expectedProfileId,
  );

  Future<Map<String, dynamic>> _sendJsonForObject(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    required AppErrorCode failureCode,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    return _sendAndDecode(
      method,
      endpoint,
      body: body == null ? null : jsonEncode(body),
      extraHeaders: body == null
          ? null
          : const {
              ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
            },
      failureCode: failureCode,
      decode: ApiResponse.decodeJsonObject,
      expectedOrigin: expectedOrigin,
      expectedProfileId: expectedProfileId,
    );
  }

  /// Sends an authorized request and decodes the response with [decode] when
  /// its status is `200`; any other status throws [ApiResponse.failure] with
  /// [failureCode].
  Future<T> _sendAndDecode<T>(
    String method,
    String endpoint, {
    Object? body,
    Map<String, String>? extraHeaders,
    required AppErrorCode failureCode,
    required T Function(http.Response response) decode,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    final response = await _sendAuthorized(
      method,
      endpoint,
      body: body,
      extraHeaders: extraHeaders,
      expectedOrigin: expectedOrigin,
      expectedProfileId: expectedProfileId,
    );
    return ApiResponse.decodeOk(response, failureCode, decode);
  }

  /// Resolves the active session, issues [method] against `<origin><endpoint>`
  /// with a bearer token, and transparently refreshes-and-retries once on a
  /// `401`. A `401` that persists after the refresh throws
  /// [AppErrorCode.sessionExpired].
  Future<http.Response> _sendAuthorized(
    String method,
    String endpoint, {
    Object? body,
    Map<String, String>? extraHeaders,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    final session = await _getValidSession(
      expectedOrigin: expectedOrigin,
      expectedProfileId: expectedProfileId,
    );
    final serverUrl = ServerUrlResolver.normalize(
      session.origin,
      config: _config,
    );
    final url = Uri.parse('$serverUrl$endpoint');

    var response = await _baseClient.send(
      method,
      url,
      extraHeaders: _authHeaders(session.accessToken, extraHeaders),
      body: body,
    );
    if (response.statusCode != 401) {
      return response;
    }

    final refreshed = await _refreshSessionAfter401(
      serverUrl: serverUrl,
      expectedOrigin: expectedOrigin,
      expectedProfileId: expectedProfileId,
    );
    response = await _baseClient.send(
      method,
      url,
      extraHeaders: _authHeaders(refreshed.accessToken, extraHeaders),
      body: body,
    );
    if (response.statusCode == 401) {
      throw const AppException(AppErrorCode.sessionExpired);
    }
    return response;
  }

  Map<String, String> _authHeaders(String token, [Map<String, String>? extra]) {
    return {ApiConstants.authorizationHeader: 'Bearer $token', ...?extra};
  }

  /// Refreshes the session after a `401`, returning the refreshed session when
  /// it still matches the expected profile and origin.
  ///
  /// Throws [AppErrorCode.transientAuthUnavailable] when the refresh could not
  /// complete but the profile's session is still present (retryable), or
  /// [AppErrorCode.sessionExpired] when the session is gone or no longer
  /// matches (terminal).
  Future<AuthSession> _refreshSessionAfter401({
    required String serverUrl,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    final refreshed = await _authService.refreshToken();
    if (!refreshed) {
      final retainedSession = await _sessionStore.readSession();
      if (_matchesExpectedProfile(
        retainedSession,
        expectedOrigin: expectedOrigin,
        expectedProfileId: expectedProfileId,
      )) {
        // The refresh could not complete (transient network/server issue) but
        // the session for this profile is still present. Signal a retryable
        // condition rather than a terminal session-expired error.
        throw const AppException(AppErrorCode.transientAuthUnavailable);
      }
      throw const AppException(AppErrorCode.sessionExpired);
    }

    final refreshedSession = await _sessionStore.readSession();
    if (!_matchesExpectedProfile(
          refreshedSession,
          expectedOrigin: expectedOrigin,
          expectedProfileId: expectedProfileId,
        ) ||
        refreshedSession!.origin != serverUrl ||
        refreshedSession.accessToken.isEmpty) {
      throw const AppException(AppErrorCode.sessionExpired);
    }
    return refreshedSession;
  }

  Future<AuthSession> _getValidSession({
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    var session = await _sessionStore.readSession();
    if (!_matchesExpectedProfile(
      session,
      expectedOrigin: expectedOrigin,
      expectedProfileId: expectedProfileId,
    )) {
      throw const AppException(AppErrorCode.notAuthenticated);
    }

    if (DateTime.now()
        .toUtc()
        .add(const Duration(minutes: 2))
        .isAfter(session!.accessTokenExpiresAt)) {
      final refreshed = await _authService.refreshToken();
      session = await _sessionStore.readSession();
      if (!_matchesExpectedProfile(
        session,
        expectedOrigin: expectedOrigin,
        expectedProfileId: expectedProfileId,
      )) {
        throw const AppException(AppErrorCode.sessionExpired);
      }
      if (!refreshed) {
        // Token expiring soon and the proactive refresh failed transiently;
        // the session is retained, so surface a retryable error.
        throw const AppException(AppErrorCode.transientAuthUnavailable);
      }
    }

    if (session!.accessToken.isEmpty) {
      throw const AppException(AppErrorCode.notAuthenticated);
    }
    return session;
  }

  bool _matchesExpectedProfile(
    AuthSession? session, {
    String? expectedOrigin,
    String? expectedProfileId,
  }) {
    if (session == null) {
      return false;
    }
    if (expectedProfileId != null && session.profileId != expectedProfileId) {
      return false;
    }
    if (expectedOrigin == null) {
      return true;
    }
    final normalizedExpected = ServerUrlResolver.normalize(
      expectedOrigin,
      config: _config,
    );
    return session.origin == normalizedExpected;
  }
}
