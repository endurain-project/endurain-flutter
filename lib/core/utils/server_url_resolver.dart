import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/secure_storage_service.dart';

/// Resolves the server base URL for a request.
///
/// Resolution order:
/// 1. The explicitly provided serverUrl (if non-empty).
/// 2. The URL stored in secure storage.
///
/// Throws an AppException with serverUrlNotConfigured when neither source
/// yields a non-empty URL.
///
/// When save is true and a serverUrl was provided, the resolved URL is
/// written back to storage so it becomes the default for future calls.
class ServerUrlResolver {
  const ServerUrlResolver({required SecureStorageService storage})
    : _storage = storage;

  final SecureStorageService _storage;

  /// Returns a non-empty, resolved server URL.
  ///
  /// If serverUrl is provided and non-empty it takes precedence over storage.
  /// Pass save as true to persist a provided URL to storage.
  Future<String> resolve({String? serverUrl, bool save = false}) async {
    String? url = serverUrl?.isNotEmpty == true ? serverUrl : null;
    url ??= await _storage.getServerUrl();

    if (url == null || url.isEmpty) {
      throw const AppException(AppErrorCode.serverUrlNotConfigured);
    }

    if (save && serverUrl != null && serverUrl.isNotEmpty) {
      await _storage.setServerUrl(url);
    }

    return url;
  }
}
