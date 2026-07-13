import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';

class StoredServerSettings {
  const StoredServerSettings({
    required this.serverUrl,
    required this.username,
    required this.tileServerUrl,
  });

  final String? serverUrl;
  final String? username;
  final String tileServerUrl;
}

/// Screen-scoped facade for the settings screen.
///
/// This intentionally aggregates the few unrelated reads/writes the settings
/// screen needs — server URL + username (auth-session concern), tile-server URL
/// (map-display concern), and logout (auth concern) — behind one dependency so
/// the screen stays thin. It is deliberately NOT a general-purpose repository:
/// each concern still lives in its own owner (`SecureStorageService`,
/// `MapSettingsRepository`, `AuthService`); this type only composes them for
/// one screen. New cross-feature settings should get their own repository
/// rather than growing this aggregator into a grab-bag.
class ServerSettingsRepository {
  const ServerSettingsRepository({
    required this._storage,
    required AuthService authService,
    required this._mapSettingsRepository,
  }) : _authService = authService;

  final SecureStorageService _storage;
  final AuthService _authService;
  final MapSettingsRepository _mapSettingsRepository;

  Future<StoredServerSettings> loadSettings() async {
    final serverUrl = await _storage.getServerUrl();
    final username = await _storage.getUsername();
    final tileServerUrl = await _mapSettingsRepository.getTileServerUrl();

    return StoredServerSettings(
      serverUrl: serverUrl,
      username: username,
      tileServerUrl: tileServerUrl.isEmpty
          ? MapConstants.defaultTileServerUrl
          : tileServerUrl,
    );
  }

  Future<void> saveTileServerUrl(String url) {
    return _mapSettingsRepository.saveTileServerUrl(url);
  }

  Future<bool> logout() {
    return _authService.logout();
  }
}
