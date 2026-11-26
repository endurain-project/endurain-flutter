import 'dart:convert';

import 'package:endurain/core/diagnostics/diagnostics_events.dart';
import 'package:endurain/core/utils/json_parsing.dart';

class DiagnosticsReport {
  const DiagnosticsReport({
    required this.rawText,
    required this.app,
    required this.schemaVersion,
    required this.lastUpdatedAt,
    required this.breadcrumbs,
    required this.errors,
    this.context = const {},
  });

  final String rawText;
  final String app;
  final int schemaVersion;
  final DateTime? lastUpdatedAt;
  final List<DiagnosticsBreadcrumb> breadcrumbs;
  final List<DiagnosticsErrorEntry> errors;

  /// The app and device the report was last written from (version, platform,
  /// OS), so a report can be read without asking which build produced it.
  final Map<String, Object?> context;

  bool get isEmpty => breadcrumbs.isEmpty && errors.isEmpty;

  factory DiagnosticsReport.fromPayload(Map<String, Object?> payload) {
    final rawText = const JsonEncoder.withIndent('  ').convert(payload);
    final breadcrumbs = payload['breadcrumbs'];
    final errors = payload['errors'];
    final context = payload['context'];

    return DiagnosticsReport(
      rawText: rawText,
      app: _stringValue(payload['app']) ?? 'Endurain',
      schemaVersion: _intValue(payload['schemaVersion']) ?? 1,
      lastUpdatedAt: _dateTimeValue(payload['lastUpdatedAt']),
      breadcrumbs: breadcrumbs is List
          ? breadcrumbs
                .whereType<Map<dynamic, dynamic>>()
                .map(DiagnosticsBreadcrumb.fromJson)
                .toList(growable: false)
          : const [],
      errors: errors is List
          ? errors
                .whereType<Map<dynamic, dynamic>>()
                .map(DiagnosticsErrorEntry.fromJson)
                .toList(growable: false)
          : const [],
      context: context is Map<dynamic, dynamic>
          ? Map<String, Object?>.fromEntries(
              context.entries.map(
                (entry) => MapEntry(entry.key.toString(), entry.value),
              ),
            )
          : const {},
    );
  }
}

class DiagnosticsBreadcrumb {
  const DiagnosticsBreadcrumb({
    required this.at,
    required this.event,
    required this.details,
  });

  final DateTime? at;
  final String event;
  final Map<String, Object?> details;

  factory DiagnosticsBreadcrumb.fromJson(Map<dynamic, dynamic> json) {
    final details = json['details'];
    return DiagnosticsBreadcrumb(
      at: _dateTimeValue(json['at']),
      event: _stringValue(json['event']) ?? 'event',
      details: details is Map<dynamic, dynamic>
          ? Map<String, Object?>.fromEntries(
              details.entries.map(
                (entry) => MapEntry(entry.key.toString(), entry.value),
              ),
            )
          : const {},
    );
  }
}

class DiagnosticsErrorEntry {
  const DiagnosticsErrorEntry({
    required this.at,
    required this.source,
    required this.type,
    required this.message,
    required this.stack,
  });

  final DateTime? at;
  final String source;
  final String type;
  final String message;
  final String stack;

  factory DiagnosticsErrorEntry.fromJson(Map<dynamic, dynamic> json) {
    return DiagnosticsErrorEntry(
      at: _dateTimeValue(json['at']),
      source: _stringValue(json['source']) ?? DiagnosticsSources.uncaught,
      type: _stringValue(json['type']) ?? 'Error',
      message: _stringValue(json['message']) ?? '',
      stack: _stringValue(json['stack']) ?? '',
    );
  }
}

String? _stringValue(Object? value) => jsonString(value);

int? _intValue(Object? value) => jsonInt(value);

// Intentionally toLocal(): diagnostic timestamps are shown to the user in
// local time, unlike activity model timestamps which are stored as UTC.
DateTime? _dateTimeValue(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}
