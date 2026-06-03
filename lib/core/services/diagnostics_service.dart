import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

abstract class DiagnosticsRecorder {
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  });

  void recordErrorSync(
    Object error,
    StackTrace stackTrace, {
    String source = DiagnosticsSources.uncaught,
  });
}

abstract class DiagnosticsStore implements DiagnosticsRecorder {
  Future<void> initialize();

  void recordFlutterErrorSync(FlutterErrorDetails details);

  Future<DiagnosticsReport?> readReport();

  Future<String?> readReportText();

  Future<void> clearReport();
}

class DiagnosticsReport {
  const DiagnosticsReport({
    required this.rawText,
    required this.app,
    required this.schemaVersion,
    required this.lastUpdatedAt,
    required this.breadcrumbs,
    required this.errors,
  });

  final String rawText;
  final String app;
  final int schemaVersion;
  final DateTime? lastUpdatedAt;
  final List<DiagnosticsBreadcrumb> breadcrumbs;
  final List<DiagnosticsErrorEntry> errors;

  bool get isEmpty => breadcrumbs.isEmpty && errors.isEmpty;

  factory DiagnosticsReport.fromPayload(Map<String, Object?> payload) {
    final rawText = const JsonEncoder.withIndent('  ').convert(payload);
    final breadcrumbs = payload['breadcrumbs'];
    final errors = payload['errors'];

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

class NoopDiagnosticsRecorder implements DiagnosticsRecorder {
  const NoopDiagnosticsRecorder();

  @override
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  }) {}

  @override
  void recordErrorSync(
    Object error,
    StackTrace stackTrace, {
    String source = DiagnosticsSources.uncaught,
  }) {}
}

class DiagnosticsSources {
  const DiagnosticsSources._();

  static const String flutter = 'flutter';
  static const String platformDispatcher = 'platform_dispatcher';
  static const String rootZone = 'root_zone';
  static const String uncaught = 'uncaught';
  static const String activityLocationStream = 'activity_location_stream';
  static const String activityRecorder = 'activity_recorder';
}

class DiagnosticsEvents {
  const DiagnosticsEvents._();

  static const String appStarted = 'app.started';
  static const String appLifecycleChanged = 'app.lifecycle_changed';
  static const String activityStartRequested = 'activity.start_requested';
  static const String activityStarted = 'activity.started';
  static const String activityStartFailed = 'activity.start_failed';
  static const String activityPaused = 'activity.paused';
  static const String activityResumed = 'activity.resumed';
  static const String activityStopped = 'activity.stopped';
  static const String activityStopFailed = 'activity.stop_failed';
  static const String activityDiscarded = 'activity.discarded';
  static const String activityFailed = 'activity.failed';
  static const String activityLocalManifestRecovered =
      'activity.local_manifest_recovered';
  static const String activityPointMilestone = 'activity.point_milestone';
  static const String activityLocationStreamDone =
      'activity.location_stream_done';
  static const String activityRecorderStarted = 'activity.recorder_started';
  static const String activityRecorderPaused = 'activity.recorder_paused';
  static const String activityRecorderResumed = 'activity.recorder_resumed';
  static const String activityRecorderStopped = 'activity.recorder_stopped';
  static const String activityRecorderFailed = 'activity.recorder_failed';
  static const String activityActiveSessionRecovered =
      'activity.active_session_recovered';
  static const String activityPointBatchDrained =
      'activity.point_batch_drained';
  static const String activityTrackingStall = 'activity.tracking_stall';
}

class DiagnosticsService implements DiagnosticsStore {
  DiagnosticsService({
    Future<Directory> Function()? supportDirectoryProvider,
    DateTime Function()? now,
    this.maxBreadcrumbs = 40,
    this.maxErrors = 8,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory,
       _now = now ?? DateTime.now;

  final Future<Directory> Function() _supportDirectoryProvider;
  final DateTime Function() _now;
  final int maxBreadcrumbs;
  final int maxErrors;

  File? _reportFile;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final directory = await _supportDirectoryProvider();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    _reportFile = File(
      '${directory.path}${Platform.pathSeparator}endurain_diagnostics.json',
    );
    _initialized = true;
  }

  @override
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  }) {
    if (!_initialized) {
      return;
    }

    final payload = _readPayloadSync();
    final breadcrumbs = _listFromPayload(payload, 'breadcrumbs');
    breadcrumbs.add({
      'at': _now().toUtc().toIso8601String(),
      'event': _sanitize(event),
      if (details.isNotEmpty) 'details': _sanitizeDetails(details),
    });
    payload['breadcrumbs'] = _trimList(breadcrumbs, maxBreadcrumbs);
    _writePayloadSync(payload);
  }

  @override
  void recordFlutterErrorSync(FlutterErrorDetails details) {
    recordErrorSync(
      details.exception,
      details.stack ?? StackTrace.empty,
      source: DiagnosticsSources.flutter,
    );
  }

  @override
  void recordErrorSync(
    Object error,
    StackTrace stackTrace, {
    String source = DiagnosticsSources.uncaught,
  }) {
    if (!_initialized) {
      return;
    }

    final payload = _readPayloadSync();
    final errors = _listFromPayload(payload, 'errors');
    errors.add({
      'at': _now().toUtc().toIso8601String(),
      'source': _sanitize(source),
      'type': _sanitize(error.runtimeType.toString()),
      'message': _sanitize(error.toString(), maxLength: 800),
      'stack': _sanitize(stackTrace.toString(), maxLength: 8000),
    });
    payload['errors'] = _trimList(errors, maxErrors);
    _writePayloadSync(payload);
  }

  @override
  Future<DiagnosticsReport?> readReport() async {
    await initialize();
    final file = _reportFile;
    if (file == null || !file.existsSync()) {
      return null;
    }

    final payload = _readPayloadSync();
    if (!_hasReportContent(payload)) {
      return null;
    }

    return DiagnosticsReport.fromPayload(payload);
  }

  @override
  Future<String?> readReportText() async {
    final report = await readReport();
    return report?.rawText;
  }

  @override
  Future<void> clearReport() async {
    await initialize();
    final file = _reportFile;
    if (file != null && file.existsSync()) {
      file.deleteSync();
    }
  }

  Map<String, Object?> _emptyPayload() {
    return {
      'schemaVersion': 1,
      'app': 'Endurain',
      'breadcrumbs': <Object?>[],
      'errors': <Object?>[],
    };
  }

  Map<String, Object?> _readPayloadSync() {
    final file = _reportFile;
    if (file == null || !file.existsSync()) {
      return _emptyPayload();
    }

    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        return Map<String, Object?>.from(decoded);
      }
    } catch (_) {
      return _emptyPayload();
    }

    return _emptyPayload();
  }

  void _writePayloadSync(Map<String, Object?> payload) {
    final file = _reportFile;
    if (file == null) {
      return;
    }

    payload['lastUpdatedAt'] = _now().toUtc().toIso8601String();
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
  }

  List<Object?> _listFromPayload(Map<String, Object?> payload, String key) {
    final value = payload[key];
    return value is List ? List<Object?>.from(value) : <Object?>[];
  }

  List<Object?> _trimList(List<Object?> values, int maxLength) {
    if (values.length <= maxLength) {
      return values;
    }
    return values.sublist(values.length - maxLength);
  }

  bool _hasReportContent(Map<String, Object?> payload) {
    final breadcrumbs = payload['breadcrumbs'];
    final errors = payload['errors'];
    return breadcrumbs is List && breadcrumbs.isNotEmpty ||
        errors is List && errors.isNotEmpty;
  }

  Map<String, Object?> _sanitizeDetails(Map<String, Object?> details) {
    final sanitized = <String, Object?>{};
    for (final entry in details.entries.take(12)) {
      sanitized[_sanitize(entry.key, maxLength: 80)] = _safeJsonValue(
        entry.value,
      );
    }
    return sanitized;
  }

  Object? _safeJsonValue(Object? value) {
    return switch (value) {
      null => null,
      bool() => value,
      num() => value,
      DateTime() => value.toUtc().toIso8601String(),
      String() => _sanitize(value),
      _ => _sanitize(value.toString()),
    };
  }

  String _sanitize(String value, {int maxLength = 500}) {
    var sanitized = value
        .replaceAll(
          RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
          'Bearer <redacted>',
        )
        .replaceAllMapped(
          RegExp(
            r'(token|password|secret|authorization|cookie|session)[=:]\s*[^,\s]+',
            caseSensitive: false,
          ),
          (match) => '${match.group(1)}=<redacted>',
        )
        .replaceAllMapped(
          RegExp(r'([?&][^=\s]+)=([^&\s]+)'),
          (match) => '${match.group(1)}=<redacted>',
        )
        .replaceAll(RegExp(r'/Users/[^\s:]+'), '<path>')
        .replaceAll(RegExp(r'/private/var/containers/[^\s:]+'), '<path>')
        .replaceAll(
          RegExp(r'[-+]?\d{1,2}\.\d{4,}\s*,\s*[-+]?\d{1,3}\.\d{4,}'),
          '<coordinates>',
        );

    if (sanitized.length > maxLength) {
      sanitized = '${sanitized.substring(0, maxLength)}...';
    }
    return sanitized;
  }
}

String? _stringValue(Object? value) {
  return value is String ? value : null;
}

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

DateTime? _dateTimeValue(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}
