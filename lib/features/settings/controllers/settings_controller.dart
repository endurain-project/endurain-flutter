import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// View-model for the settings screen.
///
/// Replaces the screen's previous `setState`-driven repository calls: the
/// screen now renders this controller's state and dispatches intents, per the
/// project's screen/controller layering rule. Loads are best-effort — settings
/// must stay reachable even when one backing store is temporarily unavailable
/// (e.g. a locked keychain), so a failure leaves that single field unset rather
/// than blocking the whole screen.
///
/// The unit preference is delegated to the app-lifetime
/// [MeasurementSystemController] rather than owned here, so changing it in
/// Settings immediately re-renders every other screen too.
class SettingsController extends SafeNotifier {
  SettingsController({
    required PackageInfoService packageInfoService,
    required MeasurementSystemController measurementSystemController,
    required SecureStorageService secureStorage,
  }) : _packageInfoService = packageInfoService,
       _measurementSystem = measurementSystemController,
       _secureStorage = secureStorage;

  final PackageInfoService _packageInfoService;
  final MeasurementSystemController _measurementSystem;
  final SecureStorageService _secureStorage;

  String? _appVersion;
  String? _serverUrl;

  /// The app version string, or `null` before it has loaded.
  String? get appVersion => _appVersion;

  /// The connected server origin, or `null` when unknown/unavailable.
  String? get serverUrl => _serverUrl;

  /// The explicit unit preference, or `null` when following the device region.
  MeasurementSystem? get measurementSystem => _measurementSystem.preference;

  /// Loads every settings value the screen renders.
  ///
  /// Each load is independent so one failing store cannot blank the others.
  Future<void> load() async {
    await Future.wait([_loadAppVersion(), _loadServerUrl()]);
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await _packageInfoService.fromPlatform();
      _appVersion = packageInfo.version;
      notify();
    } catch (_) {
      // Version is cosmetic; leave it unset rather than failing the screen.
    }
  }

  Future<void> _loadServerUrl() async {
    try {
      _serverUrl = await _secureStorage.getServerUrl();
      notify();
    } catch (_) {
      // Settings stays usable when secure storage is temporarily unavailable;
      // the server details screen surfaces storage errors directly.
    }
  }

  /// Persists the unit preference. `null` restores the device-region default.
  ///
  /// Delegated to the app-lifetime controller so every screen re-renders.
  Future<void> setMeasurementSystem(MeasurementSystem? system) async {
    await _measurementSystem.setPreference(system);
    notify();
  }
}
