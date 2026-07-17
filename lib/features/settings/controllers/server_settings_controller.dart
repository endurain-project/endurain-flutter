import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:flutter/foundation.dart';

/// Outcome of the tile-server host policy check for a candidate URL.
///
/// The controller decides the policy; the screen owns the matching UI
/// (proceed, confirm dialog, or reject dialog).
enum TileServerHostDecision {
  /// The host is acceptable and saving may proceed without a prompt.
  allowed,

  /// The host differs from the connected server host; ask the user to confirm.
  needsConfirmation,

  /// The host is not in the managed allowlist and must be rejected outright.
  blocked,
}

/// View-model for the server settings screen.
///
/// Owns the loaded account/tile-server state and the tile-host save policy so
/// the screen stays a thin view: it renders [ChangeNotifier] state and defers
/// every data read/write and policy decision to this controller. Dialogs,
/// navigation, and form validation remain in the screen (UI concerns).
class ServerSettingsController extends ChangeNotifier {
  ServerSettingsController({
    required ServerSettingsRepository repository,
    required AppConfig config,
  }) : _repository = repository,
       _config = config;

  final ServerSettingsRepository _repository;
  final AppConfig _config;

  bool _isLoading = true;
  String? _serverUrl;
  String? _username;
  String _tileServerUrl = '';

  /// Whether the initial [load] is still in progress.
  bool get isLoading => _isLoading;

  /// The stored server origin, or `null` when no server is configured. The
  /// screen applies its own localized fallback for display.
  String? get serverUrl => _serverUrl;

  /// The stored username, or `null` when not logged in. The screen applies its
  /// own localized fallback for display.
  String? get username => _username;

  /// The tile-server URL to pre-fill in the form (defaulted by the repository).
  String get tileServerUrl => _tileServerUrl;

  /// The active runtime config, exposed so the screen's form validator can
  /// apply the same managed/self-hosted transport rules used by the policy.
  AppConfig get config => _config;

  /// Loads the account and tile-server settings, emitting a loading state
  /// first so the screen can show a spinner.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final settings = await _repository.loadSettings();
    _serverUrl = settings.serverUrl;
    _username = settings.username;
    _tileServerUrl = settings.tileServerUrl;
    _isLoading = false;
    notifyListeners();
  }

  /// Applies the tile-host policy for a candidate [tileUrl].
  ///
  /// A host that is empty or matches the connected server host is
  /// [TileServerHostDecision.allowed]; a host outside the managed allowlist is
  /// [TileServerHostDecision.blocked]; any other cross-host value
  /// [TileServerHostDecision.needsConfirmation].
  TileServerHostDecision evaluateTileHost(String tileUrl) {
    final tileHost = Uri.tryParse(tileUrl)?.host;
    if (tileHost == null || tileHost.isEmpty) {
      return TileServerHostDecision.allowed;
    }
    if (!_config.isTileServerHostAllowed(tileHost)) {
      return TileServerHostDecision.blocked;
    }
    final serverHost = Uri.tryParse(_serverUrl ?? '')?.host;
    if (serverHost == null || serverHost.isEmpty || serverHost == tileHost) {
      return TileServerHostDecision.allowed;
    }
    return TileServerHostDecision.needsConfirmation;
  }

  /// Persists the tile-server [url]. May throw an `AppException` surfaced by
  /// the repository, which the screen catches to show an error dialog.
  Future<void> saveTileServerUrl(String url) {
    return _repository.saveTileServerUrl(url);
  }

  /// Signs out of the server. Returns `true` when the server-side logout
  /// succeeded; local tokens are always cleared regardless.
  Future<bool> logout() {
    return _repository.logout();
  }
}
