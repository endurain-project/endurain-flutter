import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/features/activity/repositories/audio_announcement_settings_repository.dart';
import 'package:endurain/features/settings/controllers/audio_announcement_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  late FakePreferencesStore preferences;
  late AudioAnnouncementSettingsRepository repository;

  AudioAnnouncementSettingsController buildController() =>
      AudioAnnouncementSettingsController(repository: repository);

  setUp(() {
    preferences = FakePreferencesStore();
    repository = AudioAnnouncementSettingsRepository(preferences: preferences);
  });

  group('AudioAnnouncementSettingsController', () {
    test('starts unloaded with default settings', () {
      final controller = buildController();
      addTearDown(controller.dispose);

      expect(controller.isLoaded, isFalse);
      expect(controller.settings.masterEnabled, isFalse);
    });

    test('load reads the persisted settings and notifies once', () async {
      await repository.setSettings(
        AudioAnnouncementSettings.defaults().copyWith(masterEnabled: true),
      );
      final controller = buildController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.settings.masterEnabled, isTrue);
      expect(notifications, 1);
    });

    test('setMasterEnabled persists and notifies once per change', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setMasterEnabled(true);

      expect(notifications, 1);
      expect((await repository.getSettings()).masterEnabled, isTrue);

      // Setting the same value again is a no-op.
      await controller.setMasterEnabled(true);
      expect(notifications, 1);
    });

    test('setDuckOtherAudio persists and notifies once per change', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setDuckOtherAudio(false);

      expect(notifications, 1);
      expect((await repository.getSettings()).duckOtherAudio, isFalse);

      await controller.setDuckOtherAudio(false);
      expect(notifications, 1);
    });

    test('setInterval only updates the targeted activity type', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.setInterval(
        ActivityType.ride,
        const AudioAnnouncementInterval(distanceMeters: 8000),
      );

      expect(
        controller.settings.intervalFor(ActivityType.ride).distanceMeters,
        8000,
      );
      expect(
        controller.settings.intervalFor(ActivityType.run).distanceMeters,
        1000,
      );
      final persisted = await repository.getSettings();
      expect(persisted.intervalFor(ActivityType.ride).distanceMeters, 8000);
    });

    test('load falls back to defaults when the read throws', () async {
      final controller = AudioAnnouncementSettingsController(
        repository: _ThrowingRepository(preferences: preferences),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.settings.masterEnabled, isFalse);
    });
  });
}

class _ThrowingRepository extends AudioAnnouncementSettingsRepository {
  const _ThrowingRepository({required super.preferences});

  @override
  Future<AudioAnnouncementSettings> getSettings() async {
    throw StateError('preferences unavailable');
  }
}
