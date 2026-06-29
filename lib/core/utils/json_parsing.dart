/// Shared JSON coercion helpers used by activity and API response models.
///
/// All helpers accept `Object?` to handle heterogeneous JSON maps without
/// explicit casting at each call site. Numeric coercions tolerate both `int`
/// and `double` values that survive JSON round-trips on different platforms.
/// DateTime values are always normalised to UTC.
library;

/// Extension that exposes a concise UTC ISO-8601 serialization for [DateTime].
extension DateTimeUtcIso on DateTime {
  /// Returns the UTC ISO-8601 representation of this instant.
  ///
  /// Equivalent to `toUtc().toIso8601String()`. Used wherever model
  /// serialization requires a stable, timezone-free timestamp.
  String toUtcIso8601() => toUtc().toIso8601String();
}

/// Returns [value] if it is a non-null [String]; otherwise `null`.
String? jsonString(Object? value) {
  return value is String ? value : null;
}

/// Returns [value] as an integer, coercing [num] via truncation.
/// Returns `null` for non-numeric values.
int? jsonInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

/// Returns [value] if it is a [bool]; otherwise `null`.
bool? jsonBool(Object? value) {
  return value is bool ? value : null;
}

/// Returns [value] as a finite double.
/// Returns `null` for non-numeric values or non-finite results (NaN, ±Inf).
double? jsonDouble(Object? value) {
  if (value is num) {
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }
  return null;
}

/// Parses [value] as a UTC [DateTime].
/// Returns `null` when [value] is not a valid ISO-8601 string.
DateTime? jsonDateTime(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toUtc();
}

/// Returns [value] as a non-empty [String], throwing [FormatException] when
/// the field is missing or empty. Use for required identifiers/paths during
/// model deserialization; [field] names the offending field in the message.
String jsonRequiredString(Object? value, String field) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing required field: $field');
}

/// Returns [value] as an [int] (coercing [num] via truncation), throwing
/// [FormatException] when it is missing or non-numeric. Use for required
/// integer fields during model deserialization; [field] names the offending
/// field in the message.
int jsonRequiredInt(Object? value, String field) {
  final parsed = jsonInt(value);
  if (parsed != null) {
    return parsed;
  }
  throw FormatException('Missing required field: $field');
}

/// Returns [value] as a UTC [DateTime], throwing [FormatException] when it is
/// missing or not a valid ISO-8601 string. Use for required timestamps during
/// model deserialization; [field] names the offending field in the message.
DateTime jsonRequiredDateTime(Object? value, String field) {
  final parsed = jsonDateTime(value);
  if (parsed != null) {
    return parsed;
  }
  throw FormatException('Invalid required field: $field');
}
