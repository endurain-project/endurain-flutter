/// Shared JSON coercion helpers used by activity and API response models.
///
/// All helpers accept `Object?` to handle heterogeneous JSON maps without
/// explicit casting at each call site. Numeric coercions tolerate both `int`
/// and `double` values that survive JSON round-trips on different platforms.
/// DateTime values are always normalised to UTC.
library;

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
