import 'package:endurain/core/utils/diagnostics_redaction.dart';
import 'package:endurain/core/utils/json_parsing.dart';

/// Turns arbitrary breadcrumb details into JSON-safe values with sensitive
/// text redacted, so nothing unvetted reaches the report file.
class DiagnosticsSanitizer {
  const DiagnosticsSanitizer._();

  static const int _maxDetailEntries = 12;

  static Map<String, Object?> details(Map<String, Object?> details) {
    final sanitized = <String, Object?>{};
    for (final entry in details.entries.take(_maxDetailEntries)) {
      sanitized[text(entry.key, maxLength: 80)] = _safeJsonValue(entry.value);
    }
    return sanitized;
  }

  static String text(String value, {int maxLength = 500}) =>
      redactDiagnosticText(value, maxLength: maxLength);

  static Object? _safeJsonValue(Object? value) {
    return switch (value) {
      null => null,
      bool() => value,
      num() => value,
      DateTime() => value.toUtcIso8601(),
      String() => text(value),
      _ => text(value.toString()),
    };
  }
}
