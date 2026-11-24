import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/diagnostics_redaction.dart';
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

/// The breadcrumb details that identify [error] without its message: its type,
/// and for an [AppException] its code, HTTP status, and the type of its cause.
///
/// Messages are left out because they can carry server text or user data; the
/// code and status are what a report reader needs to tell failures apart.
Map<String, Object?> diagnosticErrorDetails(Object error) {
  return {
    'type': error.runtimeType.toString(),
    if (error is AppException) ...{
      'code': error.code.name,
      'status': ?error.statusCode,
      if (error.cause != null) 'cause': error.cause.runtimeType.toString(),
    },
  };
}

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
  static const String activityAutoPaused = 'activity.auto_paused';
  static const String activityAutoResumed = 'activity.auto_resumed';
  static const String activityStopped = 'activity.stopped';
  static const String activityStopFailed = 'activity.stop_failed';
  static const String secureStorageServerUrlFallback =
      'secure_storage.server_url_fallback';
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
  static const String activityRecorderAutoPaused =
      'activity.recorder_auto_paused';
  static const String activityRecorderAutoResumed =
      'activity.recorder_auto_resumed';
  static const String activityRecorderStopped = 'activity.recorder_stopped';
  static const String activityRecorderFailed = 'activity.recorder_failed';
  static const String activityActiveSessionRecovered =
      'activity.active_session_recovered';
  static const String activityStaleSessionCleared =
      'activity.stale_session_cleared';
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
  static const String healthLoadStatusFailed = 'health.load_status_failed';
  static const String healthAutoSyncSettingFailed =
      'health.auto_sync_setting_failed';
  static const String healthRequestAccessFailed =
      'health.request_access_failed';
  static const String healthInstallProviderFailed =
      'health.install_provider_failed';
  static const String healthDisconnectFailed = 'health.disconnect_failed';
  static const String healthLoadImportableFailed =
      'health.load_importable_failed';
  static const String healthImportSelectedFailed =
      'health.import_selected_failed';
  static const String ssoProvidersFetchFailed = 'sso.providers_fetch_failed';
  static const String ssoRedirectNotAllowed = 'sso.redirect_not_allowed';
  static const String ssoLoginStarted = 'sso.login_started';
  static const String ssoBrowserLaunchFailed = 'sso.browser_launch_failed';
  static const String ssoCallbackIgnored = 'sso.callback_ignored';
  static const String ssoCallbackReceived = 'sso.callback_received';
  static const String ssoCallbackError = 'sso.callback_error';
  static const String ssoCallbackMissingSession =
      'sso.callback_missing_session';
  static const String ssoExchangeSucceeded = 'sso.exchange_succeeded';
  static const String ssoExchangeFailed = 'sso.exchange_failed';
  static const String navigationChanged = 'nav.changed';
  static const String navigationRedirected = 'nav.redirected';
  static const String navigationTabChanged = 'nav.tab_changed';
  static const String uiErrorShown = 'ui.error_shown';
  static const String sessionModeChanged = 'session.mode_changed';
  static const String sessionRevalidateFailed = 'session.revalidate_failed';
  static const String authRefreshFailed = 'auth.refresh_failed';
  static const String authSessionCleared = 'auth.session_cleared';
  static const String httpRequestFailed = 'http.request_failed';
  static const String legacyProfileAdopted = 'account.legacy_profile_adopted';
  static const String legacyProfileDeclined = 'account.legacy_profile_declined';
  static const String legacyProfileMigrationFailed =
      'account.legacy_profile_migration_failed';
}

class DiagnosticsService implements DiagnosticsStore {
  DiagnosticsService({
    Future<Directory> Function()? supportDirectoryProvider,
    DateTime Function()? now,
    this.maxBreadcrumbs = 150,
    this.maxErrors = 10,
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
  Map<String, Object?> _context = const {};

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

  /// Sets the report header describing this launch (app version, platform,
  /// OS). Values are sanitized like breadcrumb details. It is written with the
  /// next breadcrumb, so it never creates a report on its own.
  void setContext(Map<String, Object?> context) {
    _context = _sanitizeDetails(context);
  }

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
      _deleteReportFiles(file);
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

    final at = _now().toUtcIso8601();
    final sanitizedDetails = details.isEmpty
        ? const <String, Object?>{}
        : _sanitizeDetails(details);
    if (event == DiagnosticsEvents.appLifecycleChanged &&
        _mergeLifecycle(at, sanitizedDetails)) {
      _scheduleFlush();
      return;
    }
    _breadcrumbs.add(<String, Object?>{
      'at': at,
      'event': _sanitize(event),
      if (sanitizedDetails.isNotEmpty) 'details': sanitizedDetails,
    });
    _trimInPlace(_breadcrumbs, maxBreadcrumbs);
    _scheduleFlush();
  }

  /// Folds a lifecycle change into the previous breadcrumb when that one is a
  /// lifecycle change too, so one trip to the background is one entry
  /// (`inactive>hidden>paused>hidden>inactive>resumed`) instead of six that
  /// push older, more useful breadcrumbs out of the buffer.
  bool _mergeLifecycle(String at, Map<String, Object?> details) {
    if (_breadcrumbs.isEmpty) {
      return false;
    }
    final last = _breadcrumbs.last;
    if (last is! Map ||
        last['event'] != DiagnosticsEvents.appLifecycleChanged) {
      return false;
    }
    final state = details['state'];
    if (state is! String) {
      return false;
    }
    final lastDetails = last['details'];
    final previous = lastDetails is Map
        ? (lastDetails['trail'] ?? lastDetails['state'])
        : null;
    final trail = [
      if (previous is String) ...previous.split(_lifecycleTrailSeparator),
      state,
    ];
    final kept = trail.length > _maxLifecycleTrail
        ? ['…', ...trail.sublist(trail.length - _maxLifecycleTrail + 1)]
        : trail;
    last['details'] = {
      'state': state,
      'trail': kept.join(_lifecycleTrailSeparator),
      'lastAt': at,
    };
    return true;
  }

  static const String _lifecycleTrailSeparator = '>';
  static const int _maxLifecycleTrail = 16;

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
    } else {
      _deleteReportFiles(file);
    }
  }

  /// Deletes the report and any staging file a killed write left behind.
  void _deleteReportFiles(File file) {
    for (final target in [
      file,
      _stagingFile(file, _syncStagingSuffix),
      _stagingFile(file, _asyncStagingSuffix),
    ]) {
      try {
        if (target.existsSync()) {
          target.deleteSync();
        }
      } catch (_) {
        // Best-effort: deletion failure must not surface to the app.
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
    // Kept until this launch calls [setContext], so a report read before then
    // still says which build wrote it.
    final context = payload['context'];
    _context = context is Map
        ? Map<String, Object?>.fromEntries(
            context.entries.map(
              (entry) => MapEntry(entry.key.toString(), entry.value),
            ),
          )
        : const {};
  }

  bool get _hasContent => _breadcrumbs.isNotEmpty || _errors.isNotEmpty;

  /// Builds the on-disk payload from the current in-memory state.
  Map<String, Object?> _currentPayload() {
    return {
      'schemaVersion': 2,
      'app': 'Endurain',
      if (_enabled) 'enabled': true,
      if (_context.isNotEmpty) 'context': _context,
      if (_lastUpdatedAt != null)
        'lastUpdatedAt': _lastUpdatedAt!.toUtcIso8601(),
      'breadcrumbs': List<Object?>.from(_breadcrumbs),
      'errors': List<Object?>.from(_errors),
    };
  }

  String _encodePayload(Map<String, Object?> payload) =>
      const JsonEncoder.withIndent('  ').convert(payload);

  // Every write goes to a staging file that is then renamed over the report.
  // Writing the report in place truncates it first, so a process killed
  // mid-write (as when the app is swiped away right after the `detached`
  // breadcrumb) left an empty or partial file; the next launch could not parse
  // it and came back with collection off, since the opt-in lives in the same
  // file. A rename either fully happens or not at all, so the last complete
  // report survives. The sync and async paths stage to separate files because
  // a sync write can run while an async one is part-way through.
  static const String _syncStagingSuffix = '.sync.tmp';
  static const String _asyncStagingSuffix = '.async.tmp';

  File _stagingFile(File file, String suffix) => File('${file.path}$suffix');

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
      _stagingFile(file, _syncStagingSuffix)
        ..writeAsStringSync(_encodePayload(_currentPayload()), flush: true)
        ..renameSync(file.path);
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
      final staging = _stagingFile(file, _asyncStagingSuffix);
      await staging.writeAsString(content, flush: true);
      await staging.rename(file.path);
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
    return redactDiagnosticText(value, maxLength: maxLength);
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
