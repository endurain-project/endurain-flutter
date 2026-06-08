import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/api_response.dart';
import 'package:endurain/core/services/multipart_upload_adapter.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';

class ApiClient {
  ApiClient({
    SecureStorageService? storage,
    AuthSessionStore? sessionStore,
    AuthService? authService,
    http.Client? httpClient,
    MultipartUploadAdapter? uploadAdapter,
  }) {
    final resolvedStore =
        sessionStore ??
        AuthSessionStore(storage: storage ?? SecureStorageService());
    _sessionStore = resolvedStore;
    _authService =
        authService ?? AuthService(sessionStore: resolvedStore, storage: storage);
    _httpClient = httpClient ?? http.Client();
    _uploadAdapter = uploadAdapter ?? const HttpMultipartUploadAdapter();
  }

  late final AuthSessionStore _sessionStore;
  late final AuthService _authService;
  late final http.Client _httpClient;
  late final MultipartUploadAdapter _uploadAdapter;

  Future<Map<String, dynamic>> getJsonObject(
    String endpoint, {
    required AppErrorCode failureCode,
  }) {
    return _makeJsonObjectRequest('GET', endpoint, failureCode: failureCode);
  }

  Future<Map<String, dynamic>> postJsonObject(
    String endpoint, {
    Map<String, dynamic>? body,
    required AppErrorCode failureCode,
  }) {
    return _makeJsonObjectRequest(
      'POST',
      endpoint,
      body: body,
      failureCode: failureCode,
    );
  }

  Future<Map<String, dynamic>> putJsonObject(
    String endpoint, {
    Map<String, dynamic>? body,
    required AppErrorCode failureCode,
  }) {
    return _makeJsonObjectRequest(
      'PUT',
      endpoint,
      body: body,
      failureCode: failureCode,
    );
  }

  Future<Map<String, dynamic>> deleteJsonObject(
    String endpoint, {
    required AppErrorCode failureCode,
  }) {
    return _makeJsonObjectRequest('DELETE', endpoint, failureCode: failureCode);
  }

  Future<Map<String, dynamic>> _makeJsonObjectRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    required AppErrorCode failureCode,
  }) async {
    final response = await _makeRequest(method, endpoint, body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiResponse.failure(response, failureCode);
    }
    return ApiResponse.decodeJsonObject(response);
  }

  /// Upload a file with multipart/form-data
  Future<http.StreamedResponse> uploadFile(
    String endpoint,
    String filePath,
    String fieldName,
  ) async {
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
    };

    http.StreamedResponse response = await _uploadAdapter.uploadFile(
      url: url,
      headers: headers,
      filePath: filePath,
      fieldName: fieldName,
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
      response = await _uploadAdapter.uploadFile(
        url: url,
        headers: headers,
        filePath: filePath,
        fieldName: fieldName,
      );
    }

    return response;
  }

  /// Execute an HTTP request with the given method, URL, headers, and optional body
  Future<http.Response> _executeRequest(
    String method,
    Uri url,
    Map<String, String> headers, {
    Map<String, dynamic>? body,
  }) async {
    switch (method) {
      case 'GET':
        return _httpClient.get(url, headers: headers);
      case 'POST':
        return _httpClient.post(
          url,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'PUT':
        return _httpClient.put(
          url,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'DELETE':
        return _httpClient.delete(url, headers: headers);
      default:
        throw AppException(AppErrorCode.unsupportedHttpMethod, details: method);
    }
  }

  /// Make an HTTP request with automatic token refresh
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
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
      ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
    };

    http.Response response = await _executeRequest(
      method,
      url,
      headers,
      body: body,
    );

    // If token expired (401), try to refresh and retry once
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Retry the request with new token
        final newAccessToken = await _sessionStore.getAccessToken();
        headers[ApiConstants.authorizationHeader] = 'Bearer $newAccessToken';
        response = await _executeRequest(method, url, headers, body: body);
      } else {
        throw const AppException(AppErrorCode.sessionExpired);
      }
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
