import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/features/activity/repositories/audio_announcement_settings_repository.dart';
import 'package:endurain/features/activity/services/audio_announcement_preview_adapter.dart';
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

    test('speakPreview forwards the config to the adapter', () async {
      final adapter = _RecordingPreviewAdapter();
      final controller = AudioAnnouncementSettingsController(
        repository: repository,
        previewAdapter: adapter,
      );
      addTearDown(controller.dispose);

      expect(await controller.speakPreview(_config()), isTrue);

      expect(adapter.configs, hasLength(1));
      expect(adapter.configs.single.metricLabel, 'Pace');
    });

    test('speakPreview reports failure instead of throwing', () async {
      final controller = AudioAnnouncementSettingsController(
        repository: repository,
        previewAdapter: const _ThrowingPreviewAdapter(),
      );
      addTearDown(controller.dispose);

      expect(await controller.speakPreview(_config()), isFalse);
    });

    test('speakPreview is a no-op on platforms without speech', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      expect(await controller.speakPreview(_config()), isTrue);
    });

    test('setInterval persists a value equal to the metric default', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      // 1 km is exactly the metric default for a run, so comparing against
      // the resolved default would skip the write and leave an imperial user
      // on the 1 mile default they just changed away from.
      await controller.setInterval(
        ActivityType.run,
        const AudioAnnouncementInterval(distanceMeters: 1000),
      );

      final persisted = await repository.getSettings();
      expect(
        persisted
            .intervalFor(
              ActivityType.run,
              measurementSystem: MeasurementSystem.imperial,
            )
            .distanceMeters,
        1000,
      );
    });
  });
}

AudioAnnouncementConfig _config() => const AudioAnnouncementConfig(
  enabled: true,
  duckOtherAudio: true,
  intervalUnit: AudioAnnouncementIntervalUnit.distance,
  distanceIntervalMeters: 1000,
  timeIntervalSeconds: 300,
  useImperialUnits: false,
  metric: AudioAnnouncementMetric.pace,
  languageTag: 'en-US',
  distanceUnitTemplate: '{value} km',
  metricUnitTemplate: '{value} min/km',
  metricLabel: 'Pace',
  messageTemplate: '{distance} {duration} {lapMetric} {overallMetric}',
);

class _RecordingPreviewAdapter implements AudioAnnouncementPreviewAdapter {
  final List<AudioAnnouncementConfig> configs = [];

  @override
  Future<void> speakPreview(AudioAnnouncementConfig config) async {
    configs.add(config);
  }
}

class _ThrowingPreviewAdapter implements AudioAnnouncementPreviewAdapter {
  const _ThrowingPreviewAdapter();

  @override
  Future<void> speakPreview(AudioAnnouncementConfig config) async {
    throw StateError('no speech engine');
  }
}

class _ThrowingRepository extends AudioAnnouncementSettingsRepository {
  const _ThrowingRepository({required super.preferences});

  @override
  Future<AudioAnnouncementSettings> getSettings() async {
    throw StateError('preferences unavailable');
  }
}
