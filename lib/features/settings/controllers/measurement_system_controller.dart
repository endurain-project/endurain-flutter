import 'dart:ui';

import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/platform/device_measurement_system_service.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// App-wide unit preference (metric vs imperial).
///
/// Mirrors `LocaleController`: owned by the composition root so the root `App`
/// can listen and rebuild the widget tree when the user switches units in
/// Settings, and every screen reads the same resolved value.
///
/// A `null` [preference] follows the operating-system measurement setting,
/// falling back to [MeasurementSystem.forLocale] when the platform cannot
/// report one.
class MeasurementSystemController extends SafeNotifier {
  MeasurementSystemController({
    required MeasurementSettingsRepository repository,
    DeviceMeasurementSystemService deviceMeasurementSystem =
        const UnsupportedDeviceMeasurementSystemService(),
  }) : _repository = repository,
       _deviceMeasurementSystem = deviceMeasurementSystem;

  final MeasurementSettingsRepository _repository;
  final DeviceMeasurementSystemService _deviceMeasurementSystem;

  MeasurementSystem? _preference;
  MeasurementSystem? _deviceDefault;
  bool _isLoaded = false;

  /// The explicit user choice, or `null` to follow the device region.
  MeasurementSystem? get preference => _preference;

  /// Whether the persisted preference has been read yet.
  bool get isLoaded => _isLoaded;

  /// Loads the persisted preference and the operating-system unit setting.
  /// On any read error the app falls back to the device region.
  Future<void> load() async {
    final preferenceFuture = _repository.getMeasurementSystem().catchError(
      (_) => null,
    );
    final deviceDefaultFuture = _deviceMeasurementSystem
        .getMeasurementSystem()
        .catchError((_) => null);
    try {
      final values = await Future.wait([preferenceFuture, deviceDefaultFuture]);
      _preference = values[0];
      _deviceDefault = values[1];
    } catch (_) {}
    _isLoaded = true;
    notify();
  }

  /// Resolves the operating-system setting, falling back to [locale]'s region.
  MeasurementSystem deviceDefault(Locale? locale) {
    return _deviceDefault ?? MeasurementSystem.forLocale(locale);
  }

  /// Resolves the explicit preference, then the device default.
  MeasurementSystem resolve(Locale? locale) {
    return _preference ?? deviceDefault(locale);
  }

  /// Selects [system] (or `null` to follow the device region), notifies
  /// listeners immediately, then persists the choice.
  Future<void> setPreference(MeasurementSystem? system) async {
    if (_preference == system) {
      return;
    }
    _preference = system;
    notify();
    await _repository.setMeasurementSystem(system);
  }
}
