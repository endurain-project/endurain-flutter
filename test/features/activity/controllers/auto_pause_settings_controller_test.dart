import 'package:endurain/features/activity/controllers/auto_pause_settings_controller.dart';
import 'package:endurain/features/activity/repositories/auto_pause_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

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
