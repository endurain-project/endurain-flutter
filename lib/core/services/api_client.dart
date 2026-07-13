import 'dart:async';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/multipart_upload_adapter.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';

/// Authenticated multipart upload surface for the Endurain API.
///
/// Resolves the stored server URL, attaches a valid bearer access token
/// (refreshing it on expiry or a 401 and retrying the upload once), and fails
/// with a typed [AppException] when no session is available. The
/// unauthenticated auth/SSO/server-settings calls that establish a session use
/// `BaseHttpClient` directly instead.
class ApiClient {
  ApiClient({
    SecureStorageService? storage,
    AuthSessionStore? sessionStore,
    AuthService? authService,
    MultipartUploadAdapter? uploadAdapter,
    Duration? uploadTimeout,
    AppConfig config = AppConfig.defaults,
  }) {
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
    _uploadTimeout = uploadTimeout ?? ApiConstants.defaultUploadTimeout;
    _uploadAdapter = uploadAdapter ?? const HttpMultipartUploadAdapter();
    _config = config;
  }

  late final AuthSessionStore _sessionStore;
  late final AuthService _authService;
  late final MultipartUploadAdapter _uploadAdapter;
  late final Duration _uploadTimeout;
  late final AppConfig _config;

  /// Upload a file with multipart/form-data
  ///
  /// When [idempotencyKey] is provided it is sent as the
  /// [ApiConstants.idempotencyKeyHeader] so a server that honors it can
  /// de-duplicate retried uploads of the same activity.
  Future<http.StreamedResponse> uploadFile(
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

    http.StreamedResponse response = await _uploadAdapter
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

    if (response.statusCode == 401) {
      await response.stream.drain<void>();
      final refreshed = await _authService.refreshToken();
      if (!refreshed) {
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

      headers[ApiConstants.authorizationHeader] =
          'Bearer ${refreshedSession.accessToken}';
      response = await _uploadAdapter
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
    }

    return response;
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
      await _authService.refreshToken();
      session = await _sessionStore.readSession();
      if (!_matchesExpectedProfile(
        session,
        expectedOrigin: expectedOrigin,
        expectedProfileId: expectedProfileId,
      )) {
        throw const AppException(AppErrorCode.sessionExpired);
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
