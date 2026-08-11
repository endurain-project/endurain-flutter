import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/app_preferences_store.dart';

/// Persists the user's preferred [MeasurementSystem] in [AppPreferencesStore].
///
/// This is a non-secret display preference, so it lives in shared preferences
/// alongside the language choice rather than in secure storage.
///
/// A missing value means "follow the device locale" — resolved through
/// [MeasurementSystem.forLocale] — so a first launch in the US shows miles
/// without the user configuring anything.
class MeasurementSettingsRepository {
  const MeasurementSettingsRepository({required this._preferences});

  static const _measurementSystemKey = 'measurement_system';

  final AppPreferencesStore _preferences;

  /// Reads the explicit preference, or `null` when following the device
  /// locale.
  Future<MeasurementSystem?> getMeasurementSystem() async {
    final stored = await _preferences.read(key: _measurementSystemKey);
    return MeasurementSystem.fromJson(stored);
  }

  /// Persists [system], or clears the preference (falling back to the device
  /// locale) when [system] is `null`.
  Future<void> setMeasurementSystem(MeasurementSystem? system) {
    if (system == null) {
      return _preferences.delete(key: _measurementSystemKey);
    }
    return _preferences.write(
      key: _measurementSystemKey,
      value: system.toJson(),
    );
  }
}
