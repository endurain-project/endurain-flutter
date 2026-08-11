import 'dart:ui';

import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// App-wide unit preference (metric vs imperial).
///
/// Mirrors `LocaleController`: owned by the composition root so the root `App`
/// can listen and rebuild the widget tree when the user switches units in
/// Settings, and every screen reads the same resolved value.
///
/// A `null` [preference] means "follow the device region", resolved through
/// [MeasurementSystem.forLocale] so a first launch in the US shows miles with
/// no configuration.
class MeasurementSystemController extends SafeNotifier {
  MeasurementSystemController({required this._repository});

  final MeasurementSettingsRepository _repository;

  MeasurementSystem? _preference;
  bool _isLoaded = false;

  /// The explicit user choice, or `null` to follow the device region.
  MeasurementSystem? get preference => _preference;

  /// Whether the persisted preference has been read yet.
  bool get isLoaded => _isLoaded;

  /// Loads the persisted preference once at startup. On any read error the app
  /// falls back to the device region.
  Future<void> load() async {
    try {
      _preference = await _repository.getMeasurementSystem();
    } catch (_) {
      _preference = null;
    }
    _isLoaded = true;
    notify();
  }

  /// The system to display for [locale]: the explicit preference when set,
  /// otherwise the convention of the locale's region.
  MeasurementSystem resolve(Locale? locale) {
    return _preference ?? MeasurementSystem.forLocale(locale);
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
