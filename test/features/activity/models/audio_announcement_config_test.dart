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
      expect(config.metric, AudioAnnouncementMetric.pace);
      expect(config.distanceUnitTemplate, contains('km'));
      expect(
        config.distanceUnitTemplate,
        contains(AudioAnnouncementConfig.valuePlaceholder),
      );
      expect(config.metricUnitTemplate, contains('min/km'));
      expect(config.metricLabel, l10n.activityStatPace);
    });

    test('enabled rides use imperial speed and a five-mile default', () {
      final config = AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: AudioAnnouncementSettings.defaults().copyWith(
          masterEnabled: true,
        ),
        activityType: ActivityType.ride,
        measurementSystem: MeasurementSystem.imperial,
        languageTag: 'en-US',
      );

      expect(config.useImperialUnits, isTrue);
      expect(config.enabled, isTrue);
      expect(config.metric, AudioAnnouncementMetric.speed);
      expect(config.distanceIntervalMeters, 5 * UnitConversions.metersPerMile);
      expect(config.distanceUnitTemplate, contains('mi'));
      expect(config.metricUnitTemplate, contains('mph'));
      expect(config.metricLabel, l10n.activityStatSpeed);
    });

    test('other activities are disabled until explicitly enabled', () {
      final disabled = AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: AudioAnnouncementSettings.defaults().copyWith(
          masterEnabled: true,
        ),
        activityType: ActivityType.other,
        measurementSystem: MeasurementSystem.metric,
        languageTag: 'en-US',
      );
      final enabledSettings = AudioAnnouncementSettings.defaults()
          .copyWith(masterEnabled: true)
          .withInterval(
            ActivityType.other,
            AudioAnnouncementSettings.defaults()
                .intervalFor(ActivityType.other)
                .copyWith(enabled: true),
          );
      final enabled = AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: enabledSettings,
        activityType: ActivityType.other,
        measurementSystem: MeasurementSystem.metric,
        languageTag: 'en-US',
      );

      expect(disabled.enabled, isFalse);
      expect(enabled.enabled, isTrue);
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

    test('message template preserves lap and overall metric tokens', () {
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
        contains(AudioAnnouncementConfig.lapMetricPlaceholder),
      );
      expect(
        config.messageTemplate,
        contains(AudioAnnouncementConfig.overallMetricPlaceholder),
      );
    });

    test('master opt-out keeps transition cues disabled', () {
      final config = AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: AudioAnnouncementSettings.defaults(),
        activityType: ActivityType.run,
        measurementSystem: MeasurementSystem.metric,
        languageTag: 'en-US',
      );

      expect(config.enabled, isFalse);
      expect(config.autoPausedMessage, 'Recording paused');
      expect(config.autoResumedMessage, 'Recording resumed');
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
      expect(map['metric'], 'pace');
      expect(map['languageTag'], 'en-US');
      expect(map['distanceUnitTemplate'], isA<String>());
      expect(map['metricUnitTemplate'], isA<String>());
      expect(map['metricLabel'], l10n.activityStatPace);
      expect(map['messageTemplate'], isA<String>());
      expect(map['autoPausedMessage'], 'Recording paused');
      expect(map['autoResumedMessage'], 'Recording resumed');
    });
  });
}
