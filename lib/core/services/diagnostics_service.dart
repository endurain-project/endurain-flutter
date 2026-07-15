import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/utils/json_parsing.dart';
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

  /// Whether local diagnostics collection is currently enabled.
  ///
  /// Collection is opt-in and disabled by default, so recording is a no-op
  /// until the user turns it on. Valid after [initialize] has completed.
  bool get isEnabled;

  /// Enables or disables local diagnostics collection and persists the choice.
  ///
  /// Disabling discards any stored report so it stops occupying device storage.
  Future<void> setEnabled(bool enabled);

  void recordFlutterErrorSync(FlutterErrorDetails details);

  Future<DiagnosticsReport?> readReport();

  Future<String?> readReportText();

  Future<void> clearReport();

  /// Flushes any buffered diagnostics to disk and awaits the write.
  Future<void> flush();
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
  static const String activityGpxGenerationFailed =
      'activity.gpx_generation_failed';
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
  static const String activityUploadQueueDrainStarted =
      'activity.upload_queue_drain_started';
  static const String activityUploadQueueDrainFinished =
      'activity.upload_queue_drain_finished';
  static const String activityUploadQueueRecordFailed =
      'activity.upload_queue_record_failed';
  static const String activityUploadRetryFailed =
      'activity.upload_retry_failed';
  static const String healthAutoSyncFailed = 'health.auto_sync_failed';
  static const String healthAuthRequested = 'health.auth_requested';
  static const String healthListImportable = 'health.list_importable';
  static const String healthImportWorkouts = 'health.import_workouts';
  static const String healthImportWorkoutFailed =
      'health.import_workout_failed';
  static const String healthConnectSdkStatus = 'health.connect_sdk_status';
  static const String healthRequestAuthorization =
      'health.request_authorization';
  static const String healthRequestAuthorizationError =
      'health.request_authorization_error';
  static const String healthInstallProviderRequested =
      'health.install_provider_requested';
  static const String healthReadWorkouts = 'health.read_workouts';
  static const String ssoProvidersFetchFailed = 'sso.providers_fetch_failed';
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
  bool _enabled = false;

  // In-memory source of truth for reads. Recording appends here synchronously
  // and never blocks on disk; the file is only a persistence mirror that is
  // flushed asynchronously (breadcrumbs) or synchronously (errors) below.
  final List<Object?> _breadcrumbs = <Object?>[];
  final List<Object?> _errors = <Object?>[];
  DateTime? _lastUpdatedAt;

  // Coalesced async-flush state. A burst of breadcrumbs collapses into a single
  // async write instead of one synchronous fsync per event (which janked the
  // platform thread while recording). Only one write runs at a time; if new
  // events arrive mid-write, [_dirty] makes the loop take one more pass.
  bool _dirty = false;
  Future<void>? _activeFlush;

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
    final payload = _readPayloadSync();
    _enabled = payload['enabled'] == true;
    _loadInMemory(payload);
    _initialized = true;
  }

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    await initialize();
    if (_enabled == enabled) {
      return;
    }
    _enabled = enabled;

    final file = _reportFile;
    if (file == null) {
      return;
    }

    if (enabled) {
      // Persist the opt-in synchronously so a restart before any event still
      // reports diagnostics as enabled.
      _writeSync();
    } else {
      // Let any in-flight async flush settle, then discard the stored report
      // so disabled diagnostics free device storage.
      await _activeFlush;
      _breadcrumbs.clear();
      _errors.clear();
      _dirty = false;
      _lastUpdatedAt = null;
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {
          // Best-effort: deletion failure must not surface to the app.
        }
      }
    }
  }

  @override
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  }) {
    if (!_initialized || !_enabled) {
      return;
    }

    _breadcrumbs.add({
      'at': _now().toUtcIso8601(),
      'event': _sanitize(event),
      if (details.isNotEmpty) 'details': _sanitizeDetails(details),
    });
    _trimInPlace(_breadcrumbs, maxBreadcrumbs);
    _scheduleFlush();
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
    if (!_initialized || !_enabled) {
      return;
    }

    _errors.add({
      'at': _now().toUtcIso8601(),
      'source': _sanitize(source),
      'type': _sanitize(error.runtimeType.toString()),
      'message': _sanitize(error.toString(), maxLength: 800),
      'stack': _sanitize(stackTrace.toString(), maxLength: 8000),
    });
    _trimInPlace(_errors, maxErrors);
    // Errors are rare and are the crash context we most want to survive a hard
    // termination, so persist synchronously rather than via the coalesced
    // async flush used for breadcrumbs. If a breadcrumb flush is mid-write it
    // snapshotted older state, so re-mark dirty to reconcile afterwards.
    _writeSync();
    _dirty = _activeFlush != null;
  }

  @override
  Future<DiagnosticsReport?> readReport() async {
    await initialize();
    if (!_hasContent) {
      return null;
    }
    return DiagnosticsReport.fromPayload(_currentPayload());
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
    if (file == null) {
      return;
    }
    // Settle any in-flight async flush before mutating so a pending write
    // cannot resurrect the just-cleared breadcrumbs on disk.
    await _activeFlush;
    _breadcrumbs.clear();
    _errors.clear();
    _dirty = false;
    if (_enabled) {
      // Keep collection enabled but drop the captured breadcrumbs and errors.
      _writeSync();
    } else if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {
        // Best-effort.
      }
    }
  }

  @override
  Future<void> flush() async {
    if (!_initialized || !_enabled) {
      return;
    }
    // Drain the in-flight write, then persist any state buffered after it.
    await _activeFlush;
    if (_dirty) {
      _scheduleFlush();
      await _activeFlush;
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

  void _loadInMemory(Map<String, Object?> payload) {
    _breadcrumbs
      ..clear()
      ..addAll(_listFromPayload(payload, 'breadcrumbs'));
    _errors
      ..clear()
      ..addAll(_listFromPayload(payload, 'errors'));
    final last = payload['lastUpdatedAt'];
    _lastUpdatedAt = last is String ? DateTime.tryParse(last)?.toUtc() : null;
  }

  bool get _hasContent => _breadcrumbs.isNotEmpty || _errors.isNotEmpty;

  /// Builds the on-disk payload from the current in-memory state.
  Map<String, Object?> _currentPayload() {
    return {
      'schemaVersion': 1,
      'app': 'Endurain',
      if (_enabled) 'enabled': true,
      if (_lastUpdatedAt != null)
        'lastUpdatedAt': _lastUpdatedAt!.toUtcIso8601(),
      'breadcrumbs': List<Object?>.from(_breadcrumbs),
      'errors': List<Object?>.from(_errors),
    };
  }

  String _encodePayload(Map<String, Object?> payload) =>
      const JsonEncoder.withIndent('  ').convert(payload);

  /// Writes the current state synchronously (fsync).
  ///
  /// Used for errors — which must survive a hard crash — and for the opt-in and
  /// clear transitions, where a durable write is both cheap and expected.
  void _writeSync() {
    final file = _reportFile;
    if (file == null) {
      return;
    }
    _lastUpdatedAt = _now();
    try {
      file.writeAsStringSync(_encodePayload(_currentPayload()), flush: true);
    } catch (_) {
      // Best-effort: diagnostics must never surface I/O errors to the app.
    }
  }

  /// Kicks a coalesced async flush for buffered breadcrumbs.
  ///
  /// The first call starts the write loop; later calls while it runs just
  /// re-mark [_dirty] so the loop makes one more pass. Only one write runs at a
  /// time, so a burst of breadcrumbs collapses into a single (or few) writes.
  void _scheduleFlush() {
    _dirty = true;
    _activeFlush ??= _runFlush();
  }

  Future<void> _runFlush() async {
    while (_dirty) {
      _dirty = false;
      await _writeAsync();
    }
    _activeFlush = null;
  }

  Future<void> _writeAsync() async {
    final file = _reportFile;
    if (file == null) {
      return;
    }
    _lastUpdatedAt = _now();
    final content = _encodePayload(_currentPayload());
    try {
      await file.writeAsString(content);
    } catch (_) {
      // Best-effort: diagnostics must never surface I/O errors to the app.
    }
  }

  List<Object?> _listFromPayload(Map<String, Object?> payload, String key) {
    final value = payload[key];
    return value is List ? List<Object?>.from(value) : <Object?>[];
  }

  void _trimInPlace(List<Object?> values, int maxLength) {
    if (values.length <= maxLength) {
      return;
    }
    values.removeRange(0, values.length - maxLength);
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
      DateTime() => value.toUtcIso8601(),
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
