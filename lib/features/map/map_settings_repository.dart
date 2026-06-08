import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/services/secure_storage_service.dart';

class MapSettingsRepository {
  const MapSettingsRepository({required SecureStorageService storage})
    : _storage = storage;

  final SecureStorageService _storage;

  Future<String> getTileServerUrl() async {
    final tileUrl = await _storage.getTileServerUrl();
    if (tileUrl == null || tileUrl.isEmpty) {
      return MapConstants.defaultTileServerUrl;
    }
    return tileUrl;
  }

  Future<void> saveTileServerUrl(String url) {
    return _storage.setTileServerUrl(url);
  }

  Future<String?> getTileServerAttribution() {
    return _storage.getTileServerAttribution();
  }

  Future<void> saveTileServerAttribution(String attribution) {
    return _storage.setTileServerAttribution(attribution);
  }

  Future<String?> getMapBackgroundColor() {
    return _storage.getMapBackgroundColor();
  }

  Future<void> saveMapBackgroundColor(String color) {
    return _storage.setMapBackgroundColor(color);
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
