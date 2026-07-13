import 'package:endurain/core/config/app_config.dart';
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
/// Throws an AppException with [AppErrorCode.insecureTransportNotAllowed] if
/// the resolved URL uses plain `http://` for an origin that requires HTTPS (the
/// configured Endurain Cloud origin; see
/// [AppConfig.allowInsecureTransportFor]). This ensures the cloud service can
/// never be reached over insecure transport even when a stored HTTP URL is
/// present.
///
/// When save is true and a serverUrl was provided, the resolved URL is
/// written back to storage so it becomes the default for future calls.
class ServerUrlResolver {
  const ServerUrlResolver({required this._storage, required AppConfig config})
    : _config = config;

  final SecureStorageService _storage;
  final AppConfig _config;

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

    url = normalize(url, config: _config);

    if (save && serverUrl != null && serverUrl.isNotEmpty) {
      await _storage.setServerUrl(url);
    }

    return url;
  }

  static String normalize(String value, {required AppConfig config}) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (!uri.isScheme('http') && !uri.isScheme('https')) ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw const AppException(AppErrorCode.serverUrlNotConfigured);
    }
    if (!config.allowInsecureTransportFor(value) && uri.isScheme('http')) {
      throw const AppException(AppErrorCode.insecureTransportNotAllowed);
    }
    final normalizedPath = uri.path == '/'
        ? ''
        : uri.path.replaceFirst(RegExp(r'/+$'), '');
    final normalizedHost = uri.host.toLowerCase().replaceFirst(
      RegExp(r'\.$'),
      '',
    );
    return uri.replace(host: normalizedHost, path: normalizedPath).toString();
  }
}
