import 'package:endurain/core/utils/json_parsing.dart';

/// Shared GPX serialization helpers used by every GPX builder
/// (`ActivityGpxBuilder`, `HealthWorkoutGpxBuilder`).
///
/// Keeping these in one place guarantees that coordinates, elevations,
/// timestamps, and XML escaping are formatted identically regardless of which
/// source produced the track, so the server receives a consistent GPX shape.

/// Project URL embedded in generated GPX `<metadata><link>` elements.
const String gpxProjectUrl = 'https://github.com/endurain-project';

/// Formats [timestamp] as a UTC ISO-8601 string for GPX `<time>` elements.
String gpxFormatTimestamp(DateTime timestamp) => timestamp.toUtcIso8601();

/// Formats a latitude/longitude value with up to 7 fraction digits.
String gpxFormatCoordinate(double value) =>
    gpxFormatDecimal(value, maxFractionDigits: 7);

/// Formats an elevation in metres with exactly 1 fraction digit minimum.
String gpxFormatElevation(double value) =>
    gpxFormatDecimal(value, maxFractionDigits: 1, minFractionDigits: 1);

/// Formats [value] with at most [maxFractionDigits] fraction digits, trimming
/// trailing zeros down to [minFractionDigits] and normalising negative zero.
String gpxFormatDecimal(
  double value, {
  required int maxFractionDigits,
  int minFractionDigits = 0,
}) {
  var text = value.toStringAsFixed(maxFractionDigits);
  if (text.startsWith('-0') && double.parse(text) == 0) {
    text = text.substring(1);
  }
  if (!text.contains('.')) {
    return text;
  }

  while (text.split('.').last.length > minFractionDigits &&
      text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }

  if (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}

/// Escapes XML special characters for safe inclusion in GPX text nodes.
String gpxEscapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
