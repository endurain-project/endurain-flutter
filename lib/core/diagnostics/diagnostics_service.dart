import 'dart:io';

import 'package:endurain/core/diagnostics/diagnostics_events.dart';
import 'package:endurain/core/diagnostics/diagnostics_report.dart';
import 'package:endurain/core/diagnostics/diagnostics_sanitizer.dart';
import 'package:endurain/core/diagnostics/diagnostics_storage.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/json_parsing.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Callers import this file for the whole diagnostics API.
export 'package:endurain/core/diagnostics/diagnostics_events.dart';
export 'package:endurain/core/diagnostics/diagnostics_report.dart';

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

  @visibleForTesting
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

  DiagnosticsStorage? _storage;
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

  // Bumped by every [_writeSync], so an async write can tell that a newer
  // report was published after it took its snapshot (see [_writeAsync]).
  int _syncWriteGeneration = 0;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final directory = await _supportDirectoryProvider();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    _storage = DiagnosticsStorage.open(directory);
    final payload = _storage!.readPayloadSync();
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
    _context = DiagnosticsSanitizer.details(context);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await initialize();
    if (_enabled == enabled) {
      return;
    }
    _enabled = enabled;

    final storage = _storage;
    if (storage == null) {
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
      storage.deleteAll();
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
        : DiagnosticsSanitizer.details(details);
    if (event == DiagnosticsEvents.appLifecycleChanged &&
        _mergeLifecycle(at, sanitizedDetails)) {
      _scheduleFlush();
      return;
    }
    _breadcrumbs.add(<String, Object?>{
      'at': at,
      'event': DiagnosticsSanitizer.text(event),
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
      'source': DiagnosticsSanitizer.text(source),
      'type': DiagnosticsSanitizer.text(error.runtimeType.toString()),
      'message': DiagnosticsSanitizer.text(error.toString(), maxLength: 800),
      'stack': DiagnosticsSanitizer.text(
        stackTrace.toString(),
        maxLength: 8000,
      ),
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
    final storage = _storage;
    if (storage == null) {
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
      storage.deleteAll();
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

  /// Writes the current state synchronously (see [DiagnosticsStorage.writeSync]).
  void _writeSync() {
    final storage = _storage;
    if (storage == null) {
      return;
    }
    _lastUpdatedAt = _now();
    _syncWriteGeneration++;
    storage.writeSync(DiagnosticsStorage.encode(_currentPayload()));
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
    final storage = _storage;
    if (storage == null) {
      return;
    }
    _lastUpdatedAt = _now();
    final generation = _syncWriteGeneration;
    final content = DiagnosticsStorage.encode(_currentPayload());
    // A sync write (an error) during the await published a newer report; this
    // snapshot predates it, so drop it. The sync write marked the flush loop
    // dirty, so the next pass writes the current state.
    await storage.writeAsync(
      content,
      isStale: () => generation != _syncWriteGeneration,
    );
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
}
