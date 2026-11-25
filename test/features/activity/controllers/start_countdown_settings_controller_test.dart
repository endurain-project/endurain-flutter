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

/// Saves or fails each length write in the order given by [outcomes].
class _ScriptedSecondsRepository extends StartCountdownSettingsRepository {
  _ScriptedSecondsRepository() : super(preferences: FakePreferencesStore());

  final List<bool> outcomes = [];

  @override
  Future<void> setSeconds(int seconds) async {
    // Yield so overlapping calls really overlap.
    await Future<void>.delayed(Duration.zero);
    if (!outcomes.removeAt(0)) {
      throw Exception('disk full');
    }
    await super.setSeconds(seconds);
  }
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

  test('overlapping saves settle on the last value actually saved', () async {
    final repository = _ScriptedSecondsRepository();
    final controller = StartCountdownSettingsController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();

    // 15 fails, then 30 fails: storage still holds the default 10.
    repository.outcomes.addAll([false, false]);
    final first = controller.setSeconds(15);
    final second = controller.setSeconds(30);
    expect(controller.seconds, 30);
    await Future.wait([first, second]);
    expect(controller.seconds, 10);
    expect(await repository.getSeconds(), 10);

    // 15 fails, then 30 succeeds: storage and screen both hold 30.
    repository.outcomes.addAll([false, true]);
    await Future.wait([controller.setSeconds(15), controller.setSeconds(30)]);
    expect(controller.seconds, 30);
    expect(await repository.getSeconds(), 30);

    // 5 succeeds, then 15 fails: back to 5, which is what storage holds.
    repository.outcomes.addAll([true, false]);
    await Future.wait([controller.setSeconds(5), controller.setSeconds(15)]);
    expect(controller.seconds, 5);
    expect(await repository.getSeconds(), 5);
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
