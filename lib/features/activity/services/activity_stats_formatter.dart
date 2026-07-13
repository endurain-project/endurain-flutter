import 'package:intl/intl.dart';

class ActivityStatsFormatter {
  const ActivityStatsFormatter();

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

  String formatDistance(double meters, {String? locale}) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${_formatDecimal(meters / 1000, 2, locale)} km';
  }

  String formatSpeed(double? metersPerSecond, {String? locale}) {
    if (metersPerSecond == null) {
      return '-';
    }
    return '${_formatDecimal(metersPerSecond * 3.6, 1, locale)} km/h';
  }

  String formatPace(double? metersPerSecond) {
    if (metersPerSecond == null || metersPerSecond <= 0) {
      return '-';
    }

    final secondsPerKilometer = (1000 / metersPerSecond).round();
    return '${secondsPerKilometer ~/ Duration.secondsPerMinute}:'
        '${_twoDigits(secondsPerKilometer % Duration.secondsPerMinute)} min/km';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _formatDecimal(double value, int fractionDigits, String? locale) {
    if (locale == null) return value.toStringAsFixed(fractionDigits);
    return NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: fractionDigits,
    ).format(value);
  }
}
