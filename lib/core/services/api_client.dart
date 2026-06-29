import 'dart:async';
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
  }) {
    final resolvedStore =
        sessionStore ??
        AuthSessionStore(storage: storage ?? SecureStorageService());
    _sessionStore = resolvedStore;
    _authService =
        authService ??
        AuthService(sessionStore: resolvedStore, storage: storage);
    _uploadTimeout = uploadTimeout ?? ApiConstants.defaultUploadTimeout;
    _uploadAdapter = uploadAdapter ?? const HttpMultipartUploadAdapter();
  }

  late final AuthSessionStore _sessionStore;
  late final AuthService _authService;
  late final MultipartUploadAdapter _uploadAdapter;
  late final Duration _uploadTimeout;

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
  }) async {
    final serverUrl = await _sessionStore.getServerUrl();
    if (serverUrl == null || serverUrl.isEmpty) {
      throw const AppException(AppErrorCode.serverUrlNotConfigured);
    }

    final accessToken = await _getValidAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const AppException(AppErrorCode.notAuthenticated);
    }

    final url = Uri.parse('$serverUrl$endpoint');
    final headers = {
      ApiConstants.authorizationHeader: 'Bearer $accessToken',
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

      final newAccessToken = await _sessionStore.getAccessToken();
      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw const AppException(AppErrorCode.sessionExpired);
      }

      headers[ApiConstants.authorizationHeader] = 'Bearer $newAccessToken';
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

  Future<String?> _getValidAccessToken() async {
    final accessToken = await _sessionStore.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return accessToken;
    }

    if (await _sessionStore.isAccessTokenExpiringSoon()) {
      await _authService.refreshToken();
      return _sessionStore.getAccessToken();
    }

    return accessToken;
  }
}
