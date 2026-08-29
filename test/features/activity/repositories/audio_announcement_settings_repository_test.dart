import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/features/activity/repositories/audio_announcement_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  late FakePreferencesStore preferences;
  late AudioAnnouncementSettingsRepository repository;

  setUp(() {
    preferences = FakePreferencesStore();
    repository = AudioAnnouncementSettingsRepository(
      preferences: preferences,
    );
  });

  group('AudioAnnouncementSettingsRepository', () {
    test('returns defaults before anything is stored', () async {
      final settings = await repository.getSettings();

      expect(settings.masterEnabled, isFalse);
      expect(settings.duckOtherAudio, isTrue);
    });

    test('round-trips a customized settings value', () async {
      final settings = AudioAnnouncementSettings.defaults()
          .copyWith(masterEnabled: true, duckOtherAudio: false)
          .withInterval(
            ActivityType.run,
            const AudioAnnouncementInterval(distanceMeters: 5000),
          );

      await repository.setSettings(settings);
      final loaded = await repository.getSettings();

      expect(loaded.masterEnabled, isTrue);
      expect(loaded.duckOtherAudio, isFalse);
      expect(loaded.intervalFor(ActivityType.run).distanceMeters, 5000);
    });
  });
}
