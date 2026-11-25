import 'package:endurain/features/activity/repositories/start_countdown_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  late FakePreferencesStore preferences;
  late StartCountdownSettingsRepository repository;

  setUp(() {
    preferences = FakePreferencesStore();
    repository = StartCountdownSettingsRepository(preferences: preferences);
  });

  test('defaults to off, 10 seconds and spoken', () async {
    final config = await repository.getConfig();

    expect(config.enabled, isFalse);
    expect(config.seconds, 10);
    expect(config.voiceEnabled, isTrue);
  });

  test('persists every preference', () async {
    await repository.setEnabled(true);
    await repository.setSeconds(15);
    await repository.setVoiceEnabled(false);

    final config = await StartCountdownSettingsRepository(
      preferences: preferences,
    ).getConfig();
    expect(config.enabled, isTrue);
    expect(config.seconds, 15);
    expect(config.voiceEnabled, isFalse);
  });

  test('clamps the countdown length on write and read', () async {
    await repository.setSeconds(1);
    expect(await repository.getSeconds(), 3);

    await preferences.write(
      key: StartCountdownSettingsRepository.secondsKey,
      value: '600',
    );
    expect(await repository.getSeconds(), 60);
  });

  test('falls back to the default for a malformed length', () async {
    await preferences.write(
      key: StartCountdownSettingsRepository.secondsKey,
      value: 'soon',
    );

    expect(await repository.getSeconds(), 10);
  });
}
