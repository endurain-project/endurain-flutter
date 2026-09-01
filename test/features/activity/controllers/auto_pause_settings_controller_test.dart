import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/features/activity/controllers/auto_pause_settings_controller.dart';
import 'package:endurain/features/activity/repositories/auto_pause_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

class _ThrowingPreferencesBackend implements AppPreferencesBackend {
  @override
  Future<void> delete(String key) => Future.error(StateError('unavailable'));

  @override
  Future<String?> read(String key) => Future.error(StateError('unavailable'));

  @override
  Future<void> write(String key, String value) =>
      Future.error(StateError('unavailable'));
}

void main() {
  late FakePreferencesStore preferences;
  late AutoPauseSettingsRepository repository;

  AutoPauseSettingsController buildController() =>
      AutoPauseSettingsController(repository: repository);

  setUp(() {
    preferences = FakePreferencesStore();
    repository = AutoPauseSettingsRepository(preferences: preferences);
  });

  group('AutoPauseSettingsController', () {
    test('starts unloaded with the safe defaults', () {
      final controller = buildController();
      addTearDown(controller.dispose);

      expect(controller.isLoaded, isFalse);
      expect(controller.enabled, isTrue);
      expect(
        controller.delaySeconds,
        AutoPauseSettingsRepository.defaultDelaySeconds,
      );
    });

    test('load reads the persisted preferences and notifies', () async {
      await repository.setEnabled(false);
      await repository.setDelaySeconds(30);
      final controller = buildController();
      addTearDown(controller.dispose);
      var notified = false;
      controller.addListener(() => notified = true);

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.enabled, isFalse);
      expect(controller.delaySeconds, 30);
      expect(notified, isTrue);
    });

    test('setEnabled updates state immediately and persists', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.setEnabled(false);

      expect(controller.enabled, isFalse);
      expect(await repository.isEnabled(), isFalse);
    });

    test('setEnabled rolls back when persistence fails', () async {
      final controller = AutoPauseSettingsController(
        repository: AutoPauseSettingsRepository(
          preferences: AppPreferencesStore(
            backend: _ThrowingPreferencesBackend(),
          ),
        ),
      );
      addTearDown(controller.dispose);

      await controller.setEnabled(false);

      expect(controller.enabled, isTrue);
    });

    test(
      'setDelaySeconds clamps out-of-range values before persisting',
      () async {
        final controller = buildController();
        addTearDown(controller.dispose);

        await controller.setDelaySeconds(500);

        expect(controller.delaySeconds, controller.maxDelaySeconds);
        expect(await repository.getDelaySeconds(), controller.maxDelaySeconds);
      },
    );

    test('setDelaySeconds rolls back when persistence fails', () async {
      final controller = AutoPauseSettingsController(
        repository: AutoPauseSettingsRepository(
          preferences: AppPreferencesStore(
            backend: _ThrowingPreferencesBackend(),
          ),
        ),
      );
      addTearDown(controller.dispose);

      await controller.setDelaySeconds(30);

      expect(
        controller.delaySeconds,
        AutoPauseSettingsRepository.defaultDelaySeconds,
      );
    });

    test('exposes the supported delay range from the repository', () {
      final controller = buildController();
      addTearDown(controller.dispose);

      expect(
        controller.minDelaySeconds,
        AutoPauseSettingsRepository.minDelaySeconds,
      );
      expect(
        controller.maxDelaySeconds,
        AutoPauseSettingsRepository.maxDelaySeconds,
      );
    });
  });
}
