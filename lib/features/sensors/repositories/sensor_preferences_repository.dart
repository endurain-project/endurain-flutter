import 'dart:convert';

import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';

/// Persists the last sensor of each kind the user connected to, so the app can
/// offer to reconnect to it automatically.
///
/// A BLE device id (a MAC-style address on Android, an opaque UUID on iOS) is
/// not a secret, so it lives in [AppPreferencesStore] rather than secure
/// storage. Each sensor kind (heart rate, power, cadence) is remembered under
/// its own key so they never overwrite one another.
class SensorPreferencesRepository {
  const SensorPreferencesRepository({required AppPreferencesStore preferences})
    : _preferences = preferences;

  /// Storage key for the remembered heart-rate strap.
  static const String rememberedHeartRateSensorKey =
      'remembered_heart_rate_sensor';

  /// Storage key for the remembered cycling power meter.
  static const String rememberedPowerSensorKey = 'remembered_power_sensor';

  /// Storage key for the remembered cadence sensor (cycling CSC or running RSC).
  static const String rememberedCadenceSensorKey = 'remembered_cadence_sensor';

  final AppPreferencesStore _preferences;

  /// Returns the sensor remembered under [key], or `null` when none is stored or
  /// the stored value is malformed.
  Future<BleSensorDevice?> getRemembered({required String key}) async {
    final raw = await _preferences.read(key: key);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final id = decoded['id'];
      final name = decoded['name'];
      if (id is! String || id.isEmpty) {
        return null;
      }
      return BleSensorDevice(id: id, name: name is String ? name : '');
    } catch (_) {
      return null;
    }
  }

  /// Persists [device] as the sensor remembered under [key].
  Future<void> saveRemembered({
    required String key,
    required BleSensorDevice device,
  }) {
    return _preferences.write(
      key: key,
      value: jsonEncode({'id': device.id, 'name': device.name}),
    );
  }

  /// Clears the sensor remembered under [key].
  Future<void> clearRemembered({required String key}) {
    return _preferences.delete(key: key);
  }
}
