import 'dart:ui';

import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/platform/device_measurement_system_service.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  late FakePreferencesStore preferences;
  late MeasurementSettingsRepository repository;

  MeasurementSystemController buildController() =>
      MeasurementSystemController(repository: repository);

  setUp(() {
    preferences = FakePreferencesStore();
    repository = MeasurementSettingsRepository(preferences: preferences);
  });

  group('MeasurementSettingsRepository', () {
    test('returns null before anything is stored', () async {
      expect(await repository.getMeasurementSystem(), isNull);
    });

    test('round-trips each system', () async {
      for (final system in MeasurementSystem.values) {
        await repository.setMeasurementSystem(system);
        expect(await repository.getMeasurementSystem(), system);
      }
    });

    test('clears the preference when set to null', () async {
      await repository.setMeasurementSystem(MeasurementSystem.imperial);
      expect(
        await repository.getMeasurementSystem(),
        MeasurementSystem.imperial,
      );

      await repository.setMeasurementSystem(null);

      expect(await repository.getMeasurementSystem(), isNull);
    });
  });

  group('MeasurementSystemController', () {
    test('starts unloaded with no preference', () {
      final controller = buildController();
      addTearDown(controller.dispose);

      expect(controller.isLoaded, isFalse);
      expect(controller.preference, isNull);
    });

    test('load reads the persisted preference and notifies', () async {
      await repository.setMeasurementSystem(MeasurementSystem.imperial);
      final controller = buildController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.preference, MeasurementSystem.imperial);
      expect(notifications, 1);
    });

    test('resolve falls back to the locale region without a preference', () {
      final controller = buildController();
      addTearDown(controller.dispose);

      expect(
        controller.resolve(const Locale('en', 'US')),
        MeasurementSystem.imperial,
      );
      expect(
        controller.resolve(const Locale('pt', 'PT')),
        MeasurementSystem.metric,
      );
    });

    test('device setting overrides the locale region after load', () async {
      final controller = MeasurementSystemController(
        repository: repository,
        deviceMeasurementSystem: const _FakeDeviceMeasurementSystemService(
          MeasurementSystem.metric,
        ),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(
        controller.resolve(const Locale('en', 'US')),
        MeasurementSystem.metric,
      );
    });

    test('an explicit preference overrides the locale region', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.setPreference(MeasurementSystem.metric);

      // A US user who explicitly chose metric keeps metric.
      expect(
        controller.resolve(const Locale('en', 'US')),
        MeasurementSystem.metric,
      );
    });

    test('setPreference persists and notifies once per change', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setPreference(MeasurementSystem.imperial);

      expect(notifications, 1);
      expect(
        await repository.getMeasurementSystem(),
        MeasurementSystem.imperial,
      );

      // Setting the same value again is a no-op.
      await controller.setPreference(MeasurementSystem.imperial);
      expect(notifications, 1);
    });

    test('setPreference(null) restores the device-region default', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.setPreference(MeasurementSystem.metric);

      await controller.setPreference(null);

      expect(controller.preference, isNull);
      expect(await repository.getMeasurementSystem(), isNull);
      expect(
        controller.resolve(const Locale('en', 'US')),
        MeasurementSystem.imperial,
      );
    });

    test('load falls back to no preference when the read throws', () async {
      final controller = MeasurementSystemController(
        repository: _ThrowingMeasurementSettingsRepository(
          preferences: preferences,
        ),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.preference, isNull);
    });
  });
}

class _ThrowingMeasurementSettingsRepository
    extends MeasurementSettingsRepository {
  const _ThrowingMeasurementSettingsRepository({required super.preferences});

  @override
  Future<MeasurementSystem?> getMeasurementSystem() async {
    throw StateError('preferences unavailable');
  }
}

class _FakeDeviceMeasurementSystemService
    implements DeviceMeasurementSystemService {
  const _FakeDeviceMeasurementSystemService(this.system);

  final MeasurementSystem? system;

  @override
  Future<MeasurementSystem?> getMeasurementSystem() async => system;
}
