import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('AudioAnnouncementConfig.build', () {
    test('resolves metric unit templates and the master/duck flags', () {
      final settings = AudioAnnouncementSettings.defaults().copyWith(
        masterEnabled: true,
        duckOtherAudio: false,
      );

      final config = AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: settings,
        activityType: ActivityType.run,
        measurementSystem: MeasurementSystem.metric,
        languageTag: 'en-US',
      );

      expect(config.enabled, isTrue);
      expect(config.duckOtherAudio, isFalse);
      expect(config.useImperialUnits, isFalse);
      expect(config.languageTag, 'en-US');
      expect(config.intervalUnit, AudioAnnouncementIntervalUnit.distance);
      expect(config.distanceIntervalMeters, 1000);
      expect(config.distanceUnitTemplate, contains('km'));
      expect(
        config.distanceUnitTemplate,
        contains(AudioAnnouncementConfig.valuePlaceholder),
      );
      expect(config.paceUnitTemplate, contains('min/km'));
    });

    test('resolves imperial unit templates', () {
      final config = AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: AudioAnnouncementSettings.defaults(),
        activityType: ActivityType.ride,
        measurementSystem: MeasurementSystem.imperial,
        languageTag: 'en-US',
      );

      expect(config.useImperialUnits, isTrue);
      expect(config.distanceUnitTemplate, contains('mi'));
      expect(config.paceUnitTemplate, contains('min/mi'));
    });

    test('uses the interval configured for the given activity type', () {
      final settings = AudioAnnouncementSettings.defaults().withInterval(
        ActivityType.hike,
        const AudioAnnouncementInterval(
          unit: AudioAnnouncementIntervalUnit.time,
          timeSeconds: 600,
        ),
      );

      final config = AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: settings,
        activityType: ActivityType.hike,
        measurementSystem: MeasurementSystem.metric,
        languageTag: 'en-US',
      );

      expect(config.intervalUnit, AudioAnnouncementIntervalUnit.time);
      expect(config.timeIntervalSeconds, 600);
    });

    test('message template preserves the distance/duration/pace tokens', () {
      final config = AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: AudioAnnouncementSettings.defaults(),
        activityType: ActivityType.run,
        measurementSystem: MeasurementSystem.metric,
        languageTag: 'en-US',
      );

      expect(
        config.messageTemplate,
        contains(AudioAnnouncementConfig.distancePlaceholder),
      );
      expect(
        config.messageTemplate,
        contains(AudioAnnouncementConfig.durationPlaceholder),
      );
      expect(
        config.messageTemplate,
        contains(AudioAnnouncementConfig.pacePlaceholder),
      );
    });

    test('toChannelMap serializes every field', () {
      final config = AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: AudioAnnouncementSettings.defaults().copyWith(
          masterEnabled: true,
        ),
        activityType: ActivityType.run,
        measurementSystem: MeasurementSystem.metric,
        languageTag: 'en-US',
      );

      final map = config.toChannelMap();

      expect(map['enabled'], isTrue);
      expect(map['duckOtherAudio'], isTrue);
      expect(map['intervalUnit'], 'distance');
      expect(map['distanceIntervalMeters'], 1000);
      expect(map['timeIntervalSeconds'], 300);
      expect(map['useImperialUnits'], isFalse);
      expect(map['languageTag'], 'en-US');
      expect(map['distanceUnitTemplate'], isA<String>());
      expect(map['paceUnitTemplate'], isA<String>());
      expect(map['messageTemplate'], isA<String>());
    });
  });
}
