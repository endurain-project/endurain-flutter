import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/l10n/app_localizations.dart';

/// Immutable, fully localized configuration for the spoken progress
/// announcements a recording emits, handed to the native recorder at `start`.
///
/// Mirrors `BackgroundLocationConfig`: the UI layer resolves every localized
/// string once (from [AppLocalizations] and the active [MeasurementSystem])
/// and the native side never reaches back into Flutter for translations, so
/// announcements keep working while the app is backgrounded or the Flutter
/// engine is detached.
///
/// [distanceUnitTemplate] and [paceUnitTemplate] are the existing
/// `unitKilometer`/`unitMile`/`unitMinutesPerKilometer`/`unitMinutesPerMile`
/// ARB messages rendered with the [valuePlaceholder] sentinel in place of the
/// real value: since those messages are simple string interpolation (no ICU
/// plural/select), the returned string is the exact per-locale template (for
/// example `"{value} km"` or, for a locale that puts the unit first, whatever
/// order that locale uses) with the sentinel still present. The native side
/// only ever does a literal substring replace, so it never has to duplicate
/// number-to-unit formatting rules for 30+ locales.
class AudioAnnouncementConfig {
  const AudioAnnouncementConfig({
    required this.enabled,
    required this.duckOtherAudio,
    required this.intervalUnit,
    required this.distanceIntervalMeters,
    required this.timeIntervalSeconds,
    required this.useImperialUnits,
    required this.languageTag,
    required this.distanceUnitTemplate,
    required this.paceUnitTemplate,
    required this.messageTemplate,
  });

  /// Sentinel substituted into the unit templates in place of a real value.
  static const String valuePlaceholder = '{value}';

  /// Sentinels substituted into [messageTemplate] in place of the rendered
  /// distance/duration/pace fragments.
  static const String distancePlaceholder = '{distance}';
  static const String durationPlaceholder = '{duration}';
  static const String pacePlaceholder = '{pace}';

  final bool enabled;
  final bool duckOtherAudio;
  final AudioAnnouncementIntervalUnit intervalUnit;
  final double distanceIntervalMeters;
  final int timeIntervalSeconds;
  final bool useImperialUnits;
  final String languageTag;
  final String distanceUnitTemplate;
  final String paceUnitTemplate;
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
    final interval = settings.intervalFor(activityType);
    final isImperial = measurementSystem == MeasurementSystem.imperial;
    return AudioAnnouncementConfig(
      enabled: settings.masterEnabled,
      duckOtherAudio: settings.duckOtherAudio,
      intervalUnit: interval.unit,
      distanceIntervalMeters: interval.distanceMeters,
      timeIntervalSeconds: interval.timeSeconds,
      useImperialUnits: isImperial,
      languageTag: languageTag,
      distanceUnitTemplate: isImperial
          ? l10n.unitMile(valuePlaceholder)
          : l10n.unitKilometer(valuePlaceholder),
      paceUnitTemplate: isImperial
          ? l10n.unitMinutesPerMile(valuePlaceholder)
          : l10n.unitMinutesPerKilometer(valuePlaceholder),
      messageTemplate: l10n.audioAnnouncementsSpokenMessage(
        distancePlaceholder,
        durationPlaceholder,
        pacePlaceholder,
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
      'languageTag': languageTag,
      'distanceUnitTemplate': distanceUnitTemplate,
      'paceUnitTemplate': paceUnitTemplate,
      'messageTemplate': messageTemplate,
    };
  }
}
