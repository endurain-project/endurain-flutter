import 'package:endurain/features/activity/controllers/start_countdown_settings_controller.dart';
import 'package:endurain/features/activity/repositories/start_countdown_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

class _FailingWritesRepository extends StartCountdownSettingsRepository {
  _FailingWritesRepository() : super(preferences: FakePreferencesStore());

  @override
  Future<void> setEnabled(bool enabled) async => throw Exception('disk full');

  @override
  Future<void> setSeconds(int seconds) async => throw Exception('disk full');

  @override
  Future<void> setVoiceEnabled(bool enabled) async =>
      throw Exception('disk full');
}

void main() {
  test('loads the stored preferences', () async {
    final repository = StartCountdownSettingsRepository(
      preferences: FakePreferencesStore(),
    );
    await repository.setEnabled(true);
    await repository.setSeconds(5);
    await repository.setVoiceEnabled(false);
    final controller = StartCountdownSettingsController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.isLoaded, isTrue);
    expect(controller.enabled, isTrue);
    expect(controller.seconds, 5);
    expect(controller.voiceEnabled, isFalse);
  });

  test('saves changes and clamps the length', () async {
    final repository = StartCountdownSettingsRepository(
      preferences: FakePreferencesStore(),
    );
    final controller = StartCountdownSettingsController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();

    await controller.setEnabled(true);
    await controller.setSeconds(99);
    await controller.setVoiceEnabled(false);

    expect(controller.seconds, 60);
    final config = await repository.getConfig();
    expect(config.enabled, isTrue);
    expect(config.seconds, 60);
    expect(config.voiceEnabled, isFalse);
  });

  test('rolls back when saving fails', () async {
    final controller = StartCountdownSettingsController(
      repository: _FailingWritesRepository(),
    );
    addTearDown(controller.dispose);
    await controller.load();

    await controller.setEnabled(true);
    await controller.setSeconds(30);
    await controller.setVoiceEnabled(false);

    expect(controller.enabled, isFalse);
    expect(controller.seconds, 10);
    expect(controller.voiceEnabled, isTrue);
  });
}
