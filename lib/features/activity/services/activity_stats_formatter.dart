import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Localized unit symbols used by [ActivityStatsFormatter].
///
/// Resolved once from [AppLocalizations] so the formatter stays a pure value
/// type: it never touches a `BuildContext` and can be unit-tested by handing it
/// explicit labels. Unit symbols live in the ARB catalogs rather than in Dart
/// because locales such as Bulgarian, Greek, Ukrainian, and Chinese
/// conventionally transliterate them (`км`, `χλμ`, `公里`).
class UnitLabels {
  const UnitLabels({
    required this.meter,
    required this.kilometer,
    required this.foot,
    required this.mile,
    required this.kilometersPerHour,
    required this.milesPerHour,
    required this.minutesPerKilometer,
    required this.minutesPerMile,
    required this.bpm,
    required this.watt,
    required this.rpm,
  });

  /// Builds the labels for the active locale.
  factory UnitLabels.of(AppLocalizations l10n) {
    return UnitLabels(
      meter: l10n.unitMeter,
      kilometer: l10n.unitKilometer,
      foot: l10n.unitFoot,
      mile: l10n.unitMile,
      kilometersPerHour: l10n.unitKilometersPerHour,
      milesPerHour: l10n.unitMilesPerHour,
      minutesPerKilometer: l10n.unitMinutesPerKilometer,
      minutesPerMile: l10n.unitMinutesPerMile,
      bpm: l10n.unitBpm,
      watt: l10n.unitWatt,
      rpm: l10n.unitRpm,
    );
  }

  final String Function(String value) meter;
  final String Function(String value) kilometer;
  final String Function(String value) foot;
  final String Function(String value) mile;
  final String Function(String value) kilometersPerHour;
  final String Function(String value) milesPerHour;
  final String Function(String value) minutesPerKilometer;
  final String Function(String value) minutesPerMile;
  final String Function(String value) bpm;
  final String Function(String value) watt;
  final String Function(String value) rpm;
}

/// Formats recorded activity statistics for display.
///
/// Values are always supplied in SI base units (metres, metres per second) —
/// the units everything is recorded and persisted in — and converted here for
/// presentation according to [system]. Changing the unit preference therefore
/// never rewrites stored data.
class ActivityStatsFormatter {
  const ActivityStatsFormatter({
    required this.labels,
    this.system = MeasurementSystem.metric,
  });

  /// Convenience constructor resolving the labels from [l10n].
  factory ActivityStatsFormatter.of(
    AppLocalizations l10n, {
    MeasurementSystem system = MeasurementSystem.metric,
  }) {
    return ActivityStatsFormatter(labels: UnitLabels.of(l10n), system: system);
  }

  final UnitLabels labels;
  final MeasurementSystem system;

  static const String _placeholder = '-';

  bool get _isImperial => system == MeasurementSystem.imperial;

  String formatDuration(int seconds) {
    final clampedSeconds = seconds < 0 ? 0 : seconds;
    final hours = clampedSeconds ~/ Duration.secondsPerHour;
    final minutes =
        (clampedSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
    final remainingSeconds = clampedSeconds % Duration.secondsPerMinute;

    if (hours > 0) {
      return '$hours:${_twoDigits(minutes)}:${_twoDigits(remainingSeconds)}';
    }
    return '$minutes:${_twoDigits(remainingSeconds)}';
  }

  /// Formats a distance, switching to the larger unit past a full
  /// kilometre/mile so short distances stay readable (`420 m`, `1.20 km`).
  String formatDistance(double meters, {String? locale}) {
    if (_isImperial) {
      if (meters < UnitConversions.metersPerMile) {
        final feet = UnitConversions.metersToFeet(meters).round();
        return labels.foot(_formatInteger(feet, locale));
      }
      return labels.mile(
        _formatDecimal(UnitConversions.metersToMiles(meters), 2, locale),
      );
    }
    if (meters < UnitConversions.metersPerKilometer) {
      return labels.meter(_formatInteger(meters.round(), locale));
    }
    return labels.kilometer(
      _formatDecimal(UnitConversions.metersToKilometers(meters), 2, locale),
    );
  }

  String formatSpeed(double? metersPerSecond, {String? locale}) {
    if (metersPerSecond == null) {
      return _placeholder;
    }
    if (_isImperial) {
      final milesPerHour =
          UnitConversions.metersToMiles(metersPerSecond) * 3600;
      return labels.milesPerHour(_formatDecimal(milesPerHour, 1, locale));
    }
    return labels.kilometersPerHour(
      _formatDecimal(metersPerSecond * 3.6, 1, locale),
    );
  }

  String formatElevation(double? meters, {String? locale}) {
    if (meters == null) {
      return _placeholder;
    }
    if (_isImperial) {
      final feet = UnitConversions.metersToFeet(meters).round();
      return labels.foot(_formatInteger(feet, locale));
    }
    return labels.meter(_formatInteger(meters.round(), locale));
  }

  String formatPace(double? metersPerSecond) {
    if (metersPerSecond == null || metersPerSecond <= 0) {
      return _placeholder;
    }

    if (_isImperial) {
      final secondsPerMile = (UnitConversions.metersPerMile / metersPerSecond)
          .round();
      return labels.minutesPerMile(_minutesAndSeconds(secondsPerMile));
    }
    final secondsPerKilometer =
        (UnitConversions.metersPerKilometer / metersPerSecond).round();
    return labels.minutesPerKilometer(_minutesAndSeconds(secondsPerKilometer));
  }

  /// Average pace for [distanceMeters] covered in [durationSeconds].
  ///
  /// Derived from total time over distance, which is how the server computes
  /// pace. Inverting the average of instantaneous speeds gives a different
  /// number whenever sample intervals are uneven.
  String formatPaceOverDistance(double? distanceMeters, int durationSeconds) {
    if (distanceMeters == null || distanceMeters <= 0 || durationSeconds <= 0) {
      return _placeholder;
    }
    return formatPace(distanceMeters / durationSeconds);
  }

  String formatHeartRate(int? bpm) {
    if (bpm == null) {
      return _placeholder;
    }
    return labels.bpm('$bpm');
  }

  String formatPower(int? watts) {
    if (watts == null) {
      return _placeholder;
    }
    return labels.watt('$watts');
  }

  String formatCadence(int? rpm) {
    if (rpm == null) {
      return _placeholder;
    }
    return labels.rpm('$rpm');
  }

  String _minutesAndSeconds(int totalSeconds) {
    return '${totalSeconds ~/ Duration.secondsPerMinute}:'
        '${_twoDigits(totalSeconds % Duration.secondsPerMinute)}';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _formatInteger(int value, String? locale) {
    if (locale == null) return value.toString();
    return NumberFormat.decimalPattern(locale).format(value);
  }

  String _formatDecimal(double value, int fractionDigits, String? locale) {
    if (locale == null) return value.toStringAsFixed(fractionDigits);
    return NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: fractionDigits,
    ).format(value);
  }
}
