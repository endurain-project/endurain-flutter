import 'package:endurain/core/services/crash_reporter.dart';
import 'package:endurain/features/settings/repositories/crash_reporting_settings_repository.dart';

/// Coordinates opt-in remote crash reporting.
///
/// Owns the persisted user choice (enabled), reports to Endurain's managed
/// diagnostics endpoint (the build-time `defaultDsn`), and drives the injected
/// [CrashReporter] transport accordingly. Business logic only — the
/// Sentry-specific work lives behind [CrashReporter].
///
/// This is intentionally independent of the local `DiagnosticsService`: the two
/// are separate opt-ins the user controls individually. Nothing is transmitted
/// until the user enables reporting AND the managed DSN is available.
class CrashReportingService {
  CrashReportingService({
    required CrashReporter reporter,
    required CrashReportingSettingsRepository settings,
    String? defaultDsn,
    String? release,
    String? environment,
  }) : _reporter = reporter,
       _settings = settings,
       _defaultDsn = defaultDsn,
       _release = release,
       _environment = environment;

  final CrashReporter _reporter;
  final CrashReportingSettingsRepository _settings;
  final String? _defaultDsn;
  final String? _release;
  final String? _environment;

  bool _enabled = false;
  bool _loaded = false;

  /// Whether the user has opted in (persisted). Valid after [load] /
  /// [initializeIfEnabled].
  bool get isEnabled => _enabled;

  /// Whether the transport is currently active (opted in + usable DSN + started).
  bool get isActive => _reporter.isActive;

  /// The DSN reporting will use: Endurain's managed default. `null` when the
  /// build ships without one (e.g. source or F-Droid builds).
  String? get effectiveDsn => _defaultDsn;

  /// Whether a structurally usable DSN is available to report with.
  bool get hasUsableDsn => isUsableCrashReportingDsn(effectiveDsn);

  /// Loads the persisted opt-in state without touching the transport.
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _enabled = await _settings.isEnabled();
    _loaded = true;
  }

  /// Starts reporting at app launch when the user has already opted in.
  Future<void> initializeIfEnabled() async {
    await load();
    if (_enabled) {
      await _applyReporterState();
    }
  }

  /// Toggles the opt-in and (de)activates the transport to match.
  Future<void> setEnabled(bool enabled) async {
    await load();
    _enabled = enabled;
    await _settings.setEnabled(enabled);
    await _applyReporterState();
  }

  /// Forwards a captured error to the transport when reporting is enabled.
  ///
  /// Best-effort and self-contained; safe to fire-and-forget from a synchronous
  /// error handler.
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? source,
  }) async {
    if (!_enabled) {
      return;
    }
    await _reporter.capture(error, stackTrace, source: source);
  }

  Future<void> _applyReporterState() async {
    final dsn = effectiveDsn;
    if (_enabled && dsn != null && isUsableCrashReportingDsn(dsn)) {
      await _reporter.start(
        dsn: dsn,
        release: _release,
        environment: _environment,
      );
    } else {
      await _reporter.stop();
    }
  }
}
