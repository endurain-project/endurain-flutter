import 'dart:convert';

import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';

/// Persists the last heart-rate sensor the user connected to, so the app can
/// offer to reconnect to it automatically.
///
/// A BLE device id (a MAC-style address on Android, an opaque UUID on iOS) is
/// not a secret, so it lives in [AppPreferencesStore] rather than secure
/// storage.
class SensorPreferencesRepository {
  const SensorPreferencesRepository({required AppPreferencesStore preferences})
    : _preferences = preferences;

  static const String _rememberedHeartRateSensorKey =
      'remembered_heart_rate_sensor';

  final AppPreferencesStore _preferences;

  /// Returns the remembered heart-rate sensor, or `null` when none is stored or
  /// the stored value is malformed.
  Future<BleSensorDevice?> getRememberedDevice() async {
    final raw = await _preferences.read(key: _rememberedHeartRateSensorKey);
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

  /// Persists [device] as the remembered heart-rate sensor.
  Future<void> saveRememberedDevice(BleSensorDevice device) {
    return _preferences.write(
      key: _rememberedHeartRateSensorKey,
      value: jsonEncode({'id': device.id, 'name': device.name}),
    );
  }

  /// Clears the remembered heart-rate sensor.
  Future<void> clearRememberedDevice() {
    return _preferences.delete(key: _rememberedHeartRateSensorKey);
  }
}
