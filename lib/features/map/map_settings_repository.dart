import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/services/app_preferences_store.dart';

class MapSettingsRepository {
  const MapSettingsRepository({required AppPreferencesStore preferences})
    : _preferences = preferences;

  static const _tileServerUrlKey = 'tile_server_url';
  static const _tileServerAttributionKey = 'tile_server_attribution';
  static const _mapBackgroundColorKey = 'map_background_color';

  final AppPreferencesStore _preferences;

  Future<String> getTileServerUrl() async {
    final tileUrl = await _preferences.read(key: _tileServerUrlKey);
    if (tileUrl == null || tileUrl.isEmpty) {
      return MapConstants.defaultTileServerUrl;
    }
    return tileUrl;
  }

  Future<void> saveTileServerUrl(String url) {
    return _preferences.write(key: _tileServerUrlKey, value: url);
  }

  Future<String?> getTileServerAttribution() {
    return _preferences.read(key: _tileServerAttributionKey);
  }

  Future<void> saveTileServerAttribution(String attribution) {
    return _preferences.write(key: _tileServerAttributionKey, value: attribution);
  }

  Future<String?> getMapBackgroundColor() {
    return _preferences.read(key: _mapBackgroundColorKey);
  }

  Future<void> saveMapBackgroundColor(String color) {
    return _preferences.write(key: _mapBackgroundColorKey, value: color);
  }

  /// Persists any map-related fields from [settings] that have non-empty
  /// values. Fields that are null or empty are not written, leaving previously
  /// stored values intact.
  Future<void> saveFromServerSettings(ServerSettings settings) async {
    final url = settings.tileserverUrl;
    if (url != null && url.isNotEmpty) {
      await saveTileServerUrl(url);
    }
    final attribution = settings.tileserverAttribution;
    if (attribution != null && attribution.isNotEmpty) {
      await saveTileServerAttribution(attribution);
    }
    final color = settings.mapBackgroundColor;
    if (color != null && color.isNotEmpty) {
      await saveMapBackgroundColor(color);
    }
  }
}
