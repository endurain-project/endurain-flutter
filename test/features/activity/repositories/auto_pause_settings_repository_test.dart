import 'package:endurain/features/activity/repositories/auto_pause_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  group('AutoPauseSettingsRepository', () {
    late FakePreferencesStore preferences;
    late AutoPauseSettingsRepository repository;

    setUp(() {
      preferences = FakePreferencesStore();
      repository = AutoPauseSettingsRepository(preferences: preferences);
    });

    test('enabled defaults to true when unset', () async {
      expect(await repository.isEnabled(), isTrue);
    });

    test('setEnabled persists and reads back', () async {
      await repository.setEnabled(false);
      expect(await repository.isEnabled(), isFalse);

      await repository.setEnabled(true);
      expect(await repository.isEnabled(), isTrue);
    });

    test('delay defaults to 5 seconds when unset', () async {
      expect(await repository.getDelaySeconds(), 5);
    });

    test('setDelaySeconds persists and reads back a valid value', () async {
      await repository.setDelaySeconds(30);
      expect(await repository.getDelaySeconds(), 30);
    });

    test('setDelaySeconds clamps below the minimum', () async {
      await repository.setDelaySeconds(1);
      expect(await repository.getDelaySeconds(), 5);
    });

    test('setDelaySeconds clamps above the maximum', () async {
      await repository.setDelaySeconds(120);
      expect(await repository.getDelaySeconds(), 60);
    });

    test(
      'getDelaySeconds falls back to the default for malformed input',
      () async {
        await preferences.write(
          key: AutoPauseSettingsRepository.delaySecondsKey,
          value: 'not-a-number',
        );

        expect(await repository.getDelaySeconds(), 5);
      },
    );

    test(
      'getConfig builds a MovementAutoPauseConfig from both preferences',
      () async {
        await repository.setEnabled(true);
        await repository.setDelaySeconds(20);

        final config = await repository.getConfig();

        expect(config.enabled, isTrue);
        expect(config.pauseDelay, const Duration(seconds: 20));
      },
    );
  });
}
