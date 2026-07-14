import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/services/app_preferences_store.dart';

class MapSettingsRepository {
  const MapSettingsRepository({
    required this._preferences,
    this.config = AppConfig.defaults,
    this.activeConnectionOrigin,
  });

  static const _tileServerUrlKey = 'tile_server_url';

  final AppPreferencesStore _preferences;
  final AppConfig config;
  final Future<String?> Function()? activeConnectionOrigin;

  /// Whether [url] is an acceptable tile-server URL to persist: a well-formed
  /// absolute `http`/`https` URL with a host. Language-free so it can guard the
  /// repository boundary without depending on localization.
  bool isValidTileServerUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty &&
        config.isTileServerHostAllowed(uri.host) &&
        (!config.isManagedOrigin(url) || uri.isScheme('https'));
  }

  Future<String> getTileServerUrl({String? origin}) async {
    final resolvedOrigin = origin ?? await activeConnectionOrigin?.call();
    if (activeConnectionOrigin != null &&
        (resolvedOrigin == null || resolvedOrigin.isEmpty)) {
      return MapConstants.defaultTileServerUrl;
    }
    final tileUrl = await _preferences.read(key: _keyForOrigin(resolvedOrigin));
    if (tileUrl == null || tileUrl.isEmpty) {
      return MapConstants.defaultTileServerUrl;
    }
    // Re-validate on read: a stored URL can become disallowed after an app
    // update (a tighter allowedTileServerHosts allowlist, or a managed build
    // that now requires HTTPS). Fall back to the default rather than serve a
    // host that current policy rejects.
    if (!isValidTileServerUrl(tileUrl)) {
      return MapConstants.defaultTileServerUrl;
    }
    return tileUrl;
  }

  /// Persists a user-provided tile-server [url].
  ///
  /// Validates at the repository boundary so an invalid URL can never be
  /// stored regardless of caller; throws [AppException] with
  /// [AppErrorCode.invalidTileServerUrl] when [url] is not a valid http/https
  /// URL.
  Future<void> saveTileServerUrl(String url, {String? origin}) async {
    if (!isValidTileServerUrl(url)) {
      throw const AppException(AppErrorCode.invalidTileServerUrl);
    }
    final resolvedOrigin = origin ?? await activeConnectionOrigin?.call();
    if (activeConnectionOrigin != null &&
        (resolvedOrigin == null || resolvedOrigin.isEmpty)) {
      throw const AppException(AppErrorCode.notAuthenticated);
    }
    return _preferences.write(key: _keyForOrigin(resolvedOrigin), value: url);
  }

  /// Persists any map-related fields from [settings] that have non-empty
  /// values. Fields that are null or empty are not written, leaving previously
  /// stored values intact.
  Future<void> saveFromServerSettings(
    ServerSettings settings, {
    required String origin,
  }) async {
    final url = settings.tileserverUrl;
    if (url != null && url.isNotEmpty && isValidTileServerUrl(url)) {
      await saveTileServerUrl(url, origin: origin);
      return;
    }
    await _preferences.delete(key: _keyForOrigin(origin));
  }

  String _keyForOrigin(String? origin) {
    if (origin == null || origin.isEmpty) return _tileServerUrlKey;
    final digest = sha256.convert(utf8.encode(origin)).toString();
    return '${_tileServerUrlKey}_$digest';
  }
}
