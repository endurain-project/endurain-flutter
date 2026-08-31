import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/l10n/app_localizations.dart';

enum AudioAnnouncementMetric {
  pace('pace'),
  speed('speed');

  const AudioAnnouncementMetric(this.apiValue);

  final String apiValue;
}

/// Immutable, fully localized configuration for the spoken progress
/// announcements a recording emits, handed to the native recorder at `start`.
///
/// Mirrors `BackgroundLocationConfig`: the UI layer resolves every localized
/// string once (from [AppLocalizations] and the active [MeasurementSystem])
/// and the native side never reaches back into Flutter for translations, so
/// announcements keep working while the app is backgrounded or the Flutter
/// engine is detached.
///
/// Unit messages are rendered with [valuePlaceholder] in place of the real
/// value. The native side only performs literal replacement, so it never has
/// to duplicate number-to-unit formatting rules for every supported locale.
class AudioAnnouncementConfig {
  const AudioAnnouncementConfig({
    required this.enabled,
    required this.duckOtherAudio,
    required this.intervalUnit,
    required this.distanceIntervalMeters,
    required this.timeIntervalSeconds,
    required this.useImperialUnits,
    required this.metric,
    required this.languageTag,
    required this.distanceUnitTemplate,
    required this.metricUnitTemplate,
    required this.metricLabel,
    required this.messageTemplate,
  });

  /// Sentinel substituted into the unit templates in place of a real value.
  static const String valuePlaceholder = '{value}';

  /// Sentinels substituted into [messageTemplate] in place of the rendered
  /// distance/duration/lap/overall fragments.
  static const String distancePlaceholder = '{distance}';
  static const String durationPlaceholder = '{duration}';
  static const String lapMetricPlaceholder = '{lapMetric}';
  static const String overallMetricPlaceholder = '{overallMetric}';

  final bool enabled;
  final bool duckOtherAudio;
  final AudioAnnouncementIntervalUnit intervalUnit;
  final double distanceIntervalMeters;
  final int timeIntervalSeconds;
  final bool useImperialUnits;
  final AudioAnnouncementMetric metric;
  final String languageTag;
  final String distanceUnitTemplate;
  final String metricUnitTemplate;
  final String metricLabel;
  final String messageTemplate;

  /// Builds the config for [activityType] from the current [settings],
  /// [measurementSystem], and localized strings in [l10n].
  factory AudioAnnouncementConfig.build({
    required AppLocalizations l10n,
    required AudioAnnouncementSettings settings,
    required ActivityType activityType,
    required MeasurementSystem measurementSystem,
    required String languageTag,
  }) {
    final isImperial = measurementSystem == MeasurementSystem.imperial;
    final interval = settings.intervalFor(
      activityType,
      measurementSystem: measurementSystem,
    );
    final metric = switch (activityType) {
      ActivityType.run ||
      ActivityType.walk ||
      ActivityType.hike => AudioAnnouncementMetric.pace,
      ActivityType.ride || ActivityType.other => AudioAnnouncementMetric.speed,
    };
    return AudioAnnouncementConfig(
      enabled: settings.masterEnabled && interval.enabled,
      duckOtherAudio: settings.duckOtherAudio,
      intervalUnit: interval.unit,
      distanceIntervalMeters: interval.distanceMeters,
      timeIntervalSeconds: interval.timeSeconds,
      useImperialUnits: isImperial,
      metric: metric,
      languageTag: languageTag,
      distanceUnitTemplate: isImperial
          ? l10n.unitMile(valuePlaceholder)
          : l10n.unitKilometer(valuePlaceholder),
      metricUnitTemplate: switch ((metric, isImperial)) {
        (AudioAnnouncementMetric.pace, true) => l10n.unitMinutesPerMile(
          valuePlaceholder,
        ),
        (AudioAnnouncementMetric.pace, false) => l10n.unitMinutesPerKilometer(
          valuePlaceholder,
        ),
        (AudioAnnouncementMetric.speed, true) => l10n.unitMilesPerHour(
          valuePlaceholder,
        ),
        (AudioAnnouncementMetric.speed, false) => l10n.unitKilometersPerHour(
          valuePlaceholder,
        ),
      },
      metricLabel: metric == AudioAnnouncementMetric.pace
          ? l10n.activityStatPace
          : l10n.activityStatSpeed,
      messageTemplate: l10n.audioAnnouncementsSpokenMessage(
        distancePlaceholder,
        durationPlaceholder,
        lapMetricPlaceholder,
        overallMetricPlaceholder,
      ),
    );
  }

  /// Serializes this config for the native `start` method-channel call.
  Map<String, Object?> toChannelMap() {
    return {
      'enabled': enabled,
      'duckOtherAudio': duckOtherAudio,
      'intervalUnit': intervalUnit.toJson(),
      'distanceIntervalMeters': distanceIntervalMeters,
      'timeIntervalSeconds': timeIntervalSeconds,
      'useImperialUnits': useImperialUnits,
      'metric': metric.apiValue,
      'languageTag': languageTag,
      'distanceUnitTemplate': distanceUnitTemplate,
      'metricUnitTemplate': metricUnitTemplate,
      'metricLabel': metricLabel,
      'messageTemplate': messageTemplate,
    };
  }
}
