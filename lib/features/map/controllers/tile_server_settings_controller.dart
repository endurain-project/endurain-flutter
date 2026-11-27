import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

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

/// View-model for the map tiles settings screen.
///
/// Owns the stored tile-server URL and the tile-host save policy so the screen
/// stays a thin view. Dialogs, navigation, and form validation remain in the
/// screen (UI concerns).
///
/// The tile URL is stored per connected server, so this screen is only offered
/// to signed-in users; [MapSettingsRepository] rejects a save without an
/// active connection.
class TileServerSettingsController extends SafeNotifier {
  TileServerSettingsController({
    required MapSettingsRepository repository,
    required AppConfig config,
    required Future<String?> Function() loadServerUrl,
  }) : _repository = repository,
       _config = config,
       _loadServerUrl = loadServerUrl;

  final MapSettingsRepository _repository;
  final AppConfig _config;
  final Future<String?> Function() _loadServerUrl;

  bool _isLoading = true;
  Object? _loadError;
  String? _serverUrl;
  String _tileServerUrl = '';

  /// Whether the initial [load] is still in progress.
  bool get isLoading => _isLoading;

  /// Whether the last [load] failed, for example because secure storage was
  /// locked. The screen then offers a retry instead of the form, since the
  /// host warning cannot be applied without the server URL.
  bool get hasLoadError => _loadError != null;

  /// The tile-server URL to pre-fill in the form (defaulted by the repository).
  String get tileServerUrl => _tileServerUrl;

  /// The active runtime config, exposed so the screen's form validator can
  /// apply the same managed/self-hosted transport rules used by the policy.
  AppConfig get config => _config;

  /// Loads the stored tile-server URL and the connected server origin,
  /// emitting a loading state first so the screen can show a spinner.
  ///
  /// A failure is recorded in [hasLoadError] rather than thrown.
  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notify();
    try {
      final results = await Future.wait([
        _repository.getTileServerUrl(),
        _loadServerUrl(),
      ]);
      _tileServerUrl = results[0]!;
      _serverUrl = results[1];
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notify();
    }
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
  Future<void> saveTileServerUrl(String url) async {
    await _repository.saveTileServerUrl(url);
    _tileServerUrl = url;
    notify();
  }
}
