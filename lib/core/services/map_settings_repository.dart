import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/core/utils/scoped_storage_key.dart';
import 'package:endurain/core/utils/validators.dart';
import 'package:flutter/foundation.dart';

/// Signals that the effective tile-server URL may have changed: a URL was
/// saved or cleared, or the active connection (and so the origin-scoped key)
/// changed. Shared by every [MapSettingsRepository] the app builds, so a
/// long-lived map can reload without being rebuilt.
class TileServerUrlChanges extends ChangeNotifier {
  /// Tells listeners to re-read the tile-server URL.
  void notifyChanged() => notifyListeners();
}

/// Reads and persists the map tile source (URL and attribution) per server
/// origin.
class MapSettingsRepository {
  const MapSettingsRepository({
    required this._preferences,
    this.config = AppConfig.defaults,
    this.activeConnectionOrigin,
    this.changes,
  });

  static const _tileServerUrlKey = 'tile_server_url';
  static const _tileAttributionKey = 'tile_server_attribution';

  final AppPreferencesStore _preferences;
  final AppConfig config;
  final Future<String?> Function()? activeConnectionOrigin;

  /// Notified after every write, so listeners re-read [getTileServerUrl].
  final TileServerUrlChanges? changes;

  /// Whether [url] is an acceptable tile-server URL to persist: a well-formed
  /// absolute `http`/`https` URL with a host, whose template has the `{z}`,
  /// `{x}` and `{y}` placeholders and no other placeholder the map cannot fill
  /// (see [Validators.isTileUrlTemplate]). Language-free so it can guard the
  /// repository boundary without depending on localization.
  bool isValidTileServerUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty &&
        Validators.isTileUrlTemplate(url) &&
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
    await _preferences.write(key: _keyForOrigin(resolvedOrigin), value: url);
    // A user-chosen URL has no known attribution; drop any attribution that
    // belonged to the previous (server-provided) source.
    await _preferences.delete(key: _attributionKeyForOrigin(resolvedOrigin));
    changes?.notifyChanged();
  }

  /// The attribution text for the tile source stored for [origin], or null
  /// when the default OpenStreetMap source is in use or none was provided.
  Future<String?> getTileAttribution({String? origin}) async {
    final resolvedOrigin = origin ?? await activeConnectionOrigin?.call();
    if (activeConnectionOrigin != null &&
        (resolvedOrigin == null || resolvedOrigin.isEmpty)) {
      return null;
    }
    final url = await getTileServerUrl(origin: resolvedOrigin);
    if (url == MapConstants.defaultTileServerUrl) {
      return null;
    }
    final text = await _preferences.read(
      key: _attributionKeyForOrigin(resolvedOrigin),
    );
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Persists any map-related fields from [settings] that have valid,
  /// non-empty values. Fields that are null, empty, or invalid are not
  /// written, leaving previously stored values (such as a tile URL the user
  /// chose for this server) intact.
  Future<void> saveFromServerSettings(
    ServerSettings settings, {
    required String origin,
  }) async {
    final url = settings.tileserverUrl;
    if (url != null && url.isNotEmpty && isValidTileServerUrl(url)) {
      await saveTileServerUrl(url, origin: origin);
      final attribution = settings.tileserverAttribution?.trim();
      if (attribution != null && attribution.isNotEmpty) {
        await _preferences.write(
          key: _attributionKeyForOrigin(origin),
          value: attribution,
        );
        changes?.notifyChanged();
      }
    }
  }

  String _attributionKeyForOrigin(String? origin) {
    if (origin == null || origin.isEmpty) return _tileAttributionKey;
    return scopedStorageKey(_tileAttributionKey, origin);
  }

  String _keyForOrigin(String? origin) {
    if (origin == null || origin.isEmpty) return _tileServerUrlKey;
    return scopedStorageKey(_tileServerUrlKey, origin);
  }
}
