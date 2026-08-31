import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioAnnouncementInterval', () {
    test('defaults to a 1km distance interval', () {
      const interval = AudioAnnouncementInterval();

      expect(interval.unit, AudioAnnouncementIntervalUnit.distance);
      expect(interval.distanceMeters, 1000);
      expect(interval.activeValue, 1000);
    });

    test('activeValue reflects the selected unit', () {
      const interval = AudioAnnouncementInterval(
        unit: AudioAnnouncementIntervalUnit.time,
        timeSeconds: 300,
      );

      expect(interval.activeValue, 300);
    });

    test('copyWith clamps distance to the supported range', () {
      const interval = AudioAnnouncementInterval();

      expect(
        interval.copyWith(distanceMeters: 1).distanceMeters,
        AudioAnnouncementInterval.minDistanceMeters,
      );
      expect(
        interval.copyWith(distanceMeters: 1000000).distanceMeters,
        AudioAnnouncementInterval.maxDistanceMeters,
      );
    });

    test('copyWith clamps time to the supported range', () {
      const interval = AudioAnnouncementInterval();

      expect(
        interval.copyWith(timeSeconds: 1).timeSeconds,
        AudioAnnouncementInterval.minTimeSeconds,
      );
      expect(
        interval.copyWith(timeSeconds: 100000).timeSeconds,
        AudioAnnouncementInterval.maxTimeSeconds,
      );
    });

    test('toJson/fromJson round-trips every field', () {
      const interval = AudioAnnouncementInterval(
        enabled: false,
        unit: AudioAnnouncementIntervalUnit.time,
        distanceMeters: 2500,
        timeSeconds: 600,
      );

      final decoded = AudioAnnouncementInterval.fromJson(interval.toJson());

      expect(decoded, interval);
    });

    test('fromJson falls back to defaults for malformed input', () {
      expect(
        AudioAnnouncementInterval.fromJson('not a map'),
        const AudioAnnouncementInterval(),
      );
      expect(
        AudioAnnouncementInterval.fromJson(null),
        const AudioAnnouncementInterval(),
      );
    });

    test('fromJson clamps out-of-range persisted values', () {
      final decoded = AudioAnnouncementInterval.fromJson({
        'unit': 'distance',
        'distanceMeters': -5,
        'timeSeconds': 999999,
      });

      expect(
        decoded.distanceMeters,
        AudioAnnouncementInterval.minDistanceMeters,
      );
      expect(decoded.timeSeconds, AudioAnnouncementInterval.maxTimeSeconds);
    });
  });

  group('AudioAnnouncementSettings', () {
    test('defaults are disabled globally with activity-specific intervals', () {
      final settings = AudioAnnouncementSettings.defaults();

      expect(settings.masterEnabled, isFalse);
      expect(settings.duckOtherAudio, isTrue);
      expect(settings.intervalFor(ActivityType.run).enabled, isTrue);
      expect(settings.intervalFor(ActivityType.walk).distanceMeters, 1000);
      expect(settings.intervalFor(ActivityType.hike).distanceMeters, 1000);
      expect(settings.intervalFor(ActivityType.ride).distanceMeters, 5000);
      expect(settings.intervalFor(ActivityType.other).enabled, isFalse);
    });

    test('imperial defaults are one or five exact miles', () {
      final settings = AudioAnnouncementSettings.defaults();

      expect(
        settings
            .intervalFor(
              ActivityType.run,
              measurementSystem: MeasurementSystem.imperial,
            )
            .distanceMeters,
        UnitConversions.metersPerMile,
      );
      expect(
        settings
            .intervalFor(
              ActivityType.ride,
              measurementSystem: MeasurementSystem.imperial,
            )
            .distanceMeters,
        5 * UnitConversions.metersPerMile,
      );
    });

    test('withInterval only replaces the targeted activity type', () {
      final settings = AudioAnnouncementSettings.defaults().withInterval(
        ActivityType.run,
        const AudioAnnouncementInterval(distanceMeters: 5000),
      );

      expect(settings.intervalFor(ActivityType.run).distanceMeters, 5000);
      expect(settings.intervalFor(ActivityType.ride).distanceMeters, 5000);
    });

    test('storedIntervalFor never substitutes a default', () {
      final settings = AudioAnnouncementSettings.defaults().withInterval(
        ActivityType.run,
        const AudioAnnouncementInterval(distanceMeters: 5000),
      );

      expect(
        settings.storedIntervalFor(ActivityType.run)?.distanceMeters,
        5000,
      );
      expect(settings.storedIntervalFor(ActivityType.ride), isNull);
    });

    test('copyWith only changes the requested fields', () {
      final settings = AudioAnnouncementSettings.defaults()
          .copyWith(masterEnabled: true)
          .withInterval(
            ActivityType.ride,
            const AudioAnnouncementInterval(
              unit: AudioAnnouncementIntervalUnit.time,
              timeSeconds: 120,
            ),
          );

      final updated = settings.copyWith(duckOtherAudio: false);

      expect(updated.masterEnabled, isTrue);
      expect(updated.duckOtherAudio, isFalse);
      expect(updated.intervalFor(ActivityType.ride).timeSeconds, 120);
    });

    test('toJsonString/fromJsonString round-trips settings', () {
      final settings = AudioAnnouncementSettings.defaults()
          .copyWith(masterEnabled: true, duckOtherAudio: false)
          .withInterval(
            ActivityType.hike,
            const AudioAnnouncementInterval(
              unit: AudioAnnouncementIntervalUnit.time,
              timeSeconds: 900,
            ),
          );

      final decoded = AudioAnnouncementSettings.fromJsonString(
        settings.toJsonString(),
      );

      expect(decoded.masterEnabled, isTrue);
      expect(decoded.duckOtherAudio, isFalse);
      expect(decoded.intervalFor(ActivityType.hike).timeSeconds, 900);
      expect(decoded.intervalFor(ActivityType.hike).enabled, isTrue);
      expect(
        decoded.intervalFor(ActivityType.hike).unit,
        AudioAnnouncementIntervalUnit.time,
      );
    });

    test('fromJsonString falls back to defaults for null/empty/malformed', () {
      expect(
        AudioAnnouncementSettings.fromJsonString(null).masterEnabled,
        isFalse,
      );
      expect(
        AudioAnnouncementSettings.fromJsonString('').masterEnabled,
        isFalse,
      );
      expect(
        AudioAnnouncementSettings.fromJsonString('{not json').masterEnabled,
        isFalse,
      );
      expect(
        AudioAnnouncementSettings.fromJsonString('"just a string"')
            .masterEnabled,
        isFalse,
      );
    });
  });
}
