import 'dart:async';

import 'package:endurain/core/diagnostics/crash_reporter.dart';
import 'package:endurain/core/utils/diagnostics_redaction.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sentry/sentry.dart';

/// [CrashReporter] backed by the pure-Dart Sentry SDK.
///
/// Speaks the Sentry protocol, so it can target the managed Endurain
/// diagnostics endpoint or any self-hosted Sentry-compatible backend such as
/// GlitchTip. It lives under `platform/` because it drives the process-global
/// Sentry hub through static calls; the rest of the app depends only on the
/// [CrashReporter] interface, which keeps this untestable seam thin and lets
/// tests inject a fake.
///
/// Privacy: reporting only ever transmits errors the app explicitly forwards.
/// Exception values are run through [redactDiagnosticText] in `beforeSend`, PII
/// collection is disabled, and breadcrumbs are dropped, so nothing sensitive
/// leaves the device even though the transport is remote.
class SentryCrashReporter implements CrashReporter {
  SentryCrashReporter();

  String? _activeDsn;

  @override
  bool get isActive => _activeDsn != null && Sentry.isEnabled;

  @override
  Future<bool> start({
    required String dsn,
    String? release,
    String? environment,
  }) async {
    if (!isUsableCrashReportingDsn(dsn)) {
      return false;
    }
    if (_activeDsn == dsn && Sentry.isEnabled) {
      return true;
    }
    if (Sentry.isEnabled) {
      await Sentry.close();
    }
    try {
      await Sentry.init((options) {
        options.dsn = dsn;
        options.release = release;
        options.environment = environment;
        options.attachStacktrace = true;
        // Belt-and-suspenders: we forward only our own errors and scrub them,
        // but make sure the SDK never enriches events with PII on its own.
        options.sendDefaultPii = false;
        options.beforeSend = scrubEvent;
        // Drop SDK-generated breadcrumbs entirely; the local diagnostics
        // recorder is the breadcrumb trail, and remote reporting is limited to
        // scrubbed error events by design.
        options.beforeBreadcrumb = (breadcrumb, hint) => null;
      });
      _activeDsn = dsn;
      return true;
    } catch (_) {
      _activeDsn = null;
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _activeDsn = null;
    if (Sentry.isEnabled) {
      await Sentry.close();
    }
  }

  @override
  Future<void> capture(
    Object error,
    StackTrace stackTrace, {
    String? source,
  }) async {
    if (!isActive) {
      return;
    }
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (source != null) {
            scope.setTag('source', source);
          }
        },
      );
    } catch (_) {
      // Reporting must never surface its own transport failures to the app.
    }
  }

  /// Redacts sensitive substrings from every free-text field of the event
  /// before it is sent, using the same rules as the local diagnostics recorder.
  ///
  /// Request data, user, extras and non-allow-listed contexts are dropped
  /// outright; the remaining strings are redacted.
  @visibleForTesting
  FutureOr<SentryEvent?> scrubEvent(SentryEvent event, Hint hint) {
    String? redact(String? value) =>
        value == null ? null : redactDiagnosticText(value, maxLength: 800);

    for (final exception in event.exceptions ?? const <SentryException>[]) {
      exception.value = redact(exception.value);
    }
    final message = event.message;
    if (message != null) {
      message.formatted = redact(message.formatted) ?? '';
      message.template = redact(message.template);
      message.params = null;
    }
    event.request = null;
    event.user = null;
    // ignore: deprecated_member_use
    event.extra = null;
    event.breadcrumbs = null;
    event.contexts.removeWhere((key, _) => !_allowedContexts.contains(key));
    event.tags = {
      for (final entry in (event.tags ?? const <String, String>{}).entries)
        entry.key: redactDiagnosticText(entry.value, maxLength: 200),
    };
    return event;
  }

  static const _allowedContexts = {'device', 'os', 'app', 'runtimes'};
}
