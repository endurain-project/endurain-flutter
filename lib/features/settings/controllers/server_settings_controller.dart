import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// View-model for the server & account settings screen.
///
/// Owns the loaded account state so the screen stays a thin view: it renders
/// notifier state and defers every data read/write to this controller.
/// Dialogs and navigation remain in the screen (UI concerns).
class ServerSettingsController extends SafeNotifier {
  ServerSettingsController({required ServerSettingsRepository repository})
    : _repository = repository;

  final ServerSettingsRepository _repository;

  bool _isLoading = true;
  String? _serverUrl;
  String? _username;

  /// Whether the initial [load] is still in progress.
  bool get isLoading => _isLoading;

  /// The stored server origin, or `null` when no server is configured. The
  /// screen applies its own localized fallback for display.
  String? get serverUrl => _serverUrl;

  /// The stored username, or `null` when not logged in. The screen applies its
  /// own localized fallback for display.
  String? get username => _username;

  /// Loads the account settings, emitting a loading state first so the screen
  /// can show a spinner.
  Future<void> load() async {
    _isLoading = true;
    notify();
    final settings = await _repository.loadSettings();
    _serverUrl = settings.serverUrl;
    _username = settings.username;
    _isLoading = false;
    notify();
  }

  /// Signs out of the server. Returns `true` when the server-side logout
  /// succeeded; local tokens are always cleared regardless.
  Future<bool> logout() {
    return _repository.logout();
  }
}
