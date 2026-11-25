import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';

class StoredServerSettings {
  const StoredServerSettings({required this.serverUrl, required this.username});

  final String? serverUrl;
  final String? username;
}

/// Screen-scoped facade for the server & account settings screen.
///
/// Composes the two auth concerns that screen needs — the stored server URL
/// and username (`SecureStorageService`) and logout (`AuthService`) — behind
/// one dependency so the screen stays thin. It is deliberately NOT a
/// general-purpose repository: each concern still lives in its own owner. The
/// tile-server URL is a map concern and has its own screen
/// (`TileServerSettingsScreen`).
class ServerSettingsRepository {
  const ServerSettingsRepository({
    required this._storage,
    required AuthService authService,
  }) : _authService = authService;

  final SecureStorageService _storage;
  final AuthService _authService;

  Future<StoredServerSettings> loadSettings() async {
    final serverUrl = await _storage.getServerUrl();
    final username = await _storage.getUsername();

    return StoredServerSettings(serverUrl: serverUrl, username: username);
  }

  Future<bool> logout() {
    return _authService.logout();
  }
}
