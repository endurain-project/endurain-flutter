import 'package:endurain/core/services/app_infrastructure.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/services/sensor_connection_adapter.dart';
import 'package:endurain/features/sensors/services/sensor_profile.dart';
import 'package:endurain/features/sensors/services/sensor_service.dart';
import 'package:endurain/features/sensors/services/universal_ble_sensor_connection_adapter.dart';
import 'package:flutter/foundation.dart';

/// Wires the external Bluetooth sensors feature: one app-lifetime
/// [SensorService] per kind (heart rate, power, cadence), plus the platform BLE
/// adapter factory and the shared reconnect/native-handoff helpers.
///
/// Depends only on [AppInfrastructure] and a `canAutoReconnect` gate. The gate
/// lets an owner (the activity feature) suppress automatic reconnects while a
/// recording holds the sensor handoff, without this module knowing anything
/// about recording — keeping the sensors → activity direction a callback, not
/// an import.
class SensorsModule {
  SensorsModule({
    required AppInfrastructure infra,
    required bool Function() canAutoReconnect,
  }) : _infra = infra,
       _canAutoReconnect = canAutoReconnect;

  final AppInfrastructure _infra;
  final bool Function() _canAutoReconnect;

  /// App-lifetime sensor coordinators keyed by kind. Owned here so a live BLE
  /// connection survives navigation between screens and can feed the recording
  /// pipeline. Route controllers observe these but must not dispose them.
  late final Map<SensorMeasurementKind, SensorService> services =
      <SensorMeasurementKind, SensorService>{
        for (final kind in SensorMeasurementKind.values)
          kind: SensorService(
            adapter: createAdapter(_profilesFor(kind)),
            preferences: SensorPreferencesRepository(
              preferences: _infra.preferences,
            ),
            rememberedKey: _rememberedKey(kind),
            canAutoReconnect: _canAutoReconnect,
          ),
      };

  /// The coordinator for [kind].
  SensorService service(SensorMeasurementKind kind) => services[kind]!;

  SensorService get heartRate => services[SensorMeasurementKind.heartRate]!;
  SensorService get power => services[SensorMeasurementKind.power]!;
  SensorService get cadence => services[SensorMeasurementKind.cadence]!;

  /// Best-effort reconnect of every remembered sensor. A no-op per kind when
  /// nothing is remembered, one is already connected, Bluetooth is off, or the
  /// `canAutoReconnect` gate currently forbids it.
  Future<void> reconnectRemembered() async {
    await Future.wait([
      for (final sensor in services.values) sensor.tryReconnectRemembered(),
    ]);
  }

  /// Hands the paired sensor of [kind] off to the native recorder for the
  /// duration of a recording: disconnects the Dart-side BLE link (so the native
  /// foreground service can own the single GATT connection) and returns the
  /// device id to record from, or `null` when no sensor of that kind is paired.
  Future<String?> prepareNativeSource(SensorMeasurementKind kind) async {
    final sensor = services[kind]!;
    final device = sensor.connectedDevice ?? await sensor.rememberedDevice();
    if (device == null) {
      return null;
    }
    await sensor.disconnect();
    return device.id;
  }

  /// Builds a BLE sensor adapter for [profiles] on the current platform.
  ///
  /// Returns the `universal_ble`-backed adapter on Android/iOS; falls back to
  /// [UnsupportedSensorConnectionAdapter] elsewhere (desktop, web, or the host
  /// test runtime) so the feature degrades gracefully without a BLE stack.
  SensorConnectionAdapter createAdapter(List<SensorProfile> profiles) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return UniversalBleSensorConnectionAdapter(profiles: profiles);
    }
    return const UnsupportedSensorConnectionAdapter();
  }

  /// The BLE GATT profiles offered for [kind].
  List<SensorProfile> _profilesFor(SensorMeasurementKind kind) {
    return switch (kind) {
      SensorMeasurementKind.heartRate => SensorProfiles.heartRate,
      SensorMeasurementKind.power => SensorProfiles.power,
      SensorMeasurementKind.cadence => SensorProfiles.cadence,
    };
  }

  /// The preferences key under which the remembered sensor of [kind] is stored.
  String _rememberedKey(SensorMeasurementKind kind) {
    return switch (kind) {
      SensorMeasurementKind.heartRate =>
        SensorPreferencesRepository.rememberedHeartRateSensorKey,
      SensorMeasurementKind.power =>
        SensorPreferencesRepository.rememberedPowerSensorKey,
      SensorMeasurementKind.cadence =>
        SensorPreferencesRepository.rememberedCadenceSensorKey,
    };
  }
}
