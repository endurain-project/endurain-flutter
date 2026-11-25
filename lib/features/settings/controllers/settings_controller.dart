import 'dart:async';

import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/shared/state/safe_notifier.dart';
import 'package:flutter/foundation.dart';

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
    Listenable? connectionChanges,
  }) : _packageInfoService = packageInfoService,
       _measurementSystem = measurementSystemController,
       _secureStorage = secureStorage,
       _connectionChanges = connectionChanges {
    // The settings tab stays alive across sign-in and sign-out, so re-read
    // the connected server whenever the session changes.
    _connectionChanges?.addListener(_handleConnectionChanged);
  }

  final PackageInfoService _packageInfoService;
  final MeasurementSystemController _measurementSystem;
  final SecureStorageService _secureStorage;
  final Listenable? _connectionChanges;

  String? _appVersion;
  String? _serverUrl;

  /// Bumped by each [_loadServerUrl], so a slower earlier read cannot
  /// overwrite the result of a later one.
  int _serverUrlGeneration = 0;

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

  void _handleConnectionChanged() {
    if (!isDisposed) {
      unawaited(_loadServerUrl());
    }
  }

  Future<void> _loadServerUrl() async {
    final generation = ++_serverUrlGeneration;
    try {
      final serverUrl = await _secureStorage.getServerUrl();
      if (generation != _serverUrlGeneration) {
        return;
      }
      _serverUrl = serverUrl;
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

  @override
  void dispose() {
    _connectionChanges?.removeListener(_handleConnectionChanged);
    super.dispose();
  }
}
