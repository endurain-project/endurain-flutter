import 'package:endurain/core/services/crash_reporting_service.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:flutter/foundation.dart';

/// View-model for the diagnostics screen.
///
/// Owns two independent opt-ins the screen renders as [ChangeNotifier] state
/// rather than driving the services directly through `setState`/`FutureBuilder`:
/// the local [DiagnosticsStore] recorder (and its loaded [DiagnosticsReport]),
/// and the opt-in remote [CrashReportingService]. The two are independent — the
/// user may enable neither, either, or both. Clipboard copy and user messaging
/// remain in the screen (UI concerns).
class DiagnosticsController extends ChangeNotifier {
  DiagnosticsController({
    required DiagnosticsStore diagnostics,
    required CrashReportingService crashReporting,
  }) : _diagnostics = diagnostics,
       _crashReporting = crashReporting,
       _isEnabled = diagnostics.isEnabled;

  final DiagnosticsStore _diagnostics;
  final CrashReportingService _crashReporting;

  bool _isEnabled;
  bool _isLoadingReport = false;
  DiagnosticsReport? _report;

  bool _crashReportingEnabled = false;

  /// Whether diagnostics collection is currently enabled.
  bool get isEnabled => _isEnabled;

  /// Whether the report is currently being (re)loaded.
  bool get isLoadingReport => _isLoadingReport;

  /// The most recently loaded report, or `null` when disabled or empty.
  DiagnosticsReport? get report => _report;

  /// Whether the user has opted in to remote crash reporting.
  bool get crashReportingEnabled => _crashReportingEnabled;

  /// Whether remote crash reporting is currently active (opted in + usable DSN).
  bool get crashReportingActive => _crashReporting.isActive;

  /// Whether the managed diagnostics endpoint is available to send to.
  bool get crashReportingHasUsableServer => _crashReporting.hasUsableDsn;

  /// Loads the current report (when enabled), emitting a loading state first.
  ///
  /// The store's [DiagnosticsStore.isEnabled] is only meaningful after
  /// [DiagnosticsStore.initialize] has completed, so ensure it has run and then
  /// re-read the persisted opt-in. Without this a store that has not been
  /// initialized yet reports `false`, leaving the toggle stuck off after a
  /// restart even though collection was enabled on disk.
  Future<void> load() async {
    await _diagnostics.initialize();
    _isEnabled = _diagnostics.isEnabled;
    await _crashReporting.load();
    _crashReportingEnabled = _crashReporting.isEnabled;
    await _refreshReport();
  }

  /// Toggles diagnostics collection and reloads the report to reflect the
  /// change (clearing it when turned off).
  Future<void> setEnabled(bool value) async {
    await _diagnostics.setEnabled(value);
    _isEnabled = value;
    await _refreshReport();
  }

  /// Toggles remote crash reporting and applies the change immediately.
  Future<void> setCrashReportingEnabled(bool value) async {
    await _crashReporting.setEnabled(value);
    _crashReportingEnabled = _crashReporting.isEnabled;
    notifyListeners();
  }

  /// Clears the persisted report and refreshes the in-memory view.
  Future<void> clearReport() async {
    await _diagnostics.clearReport();
    await _refreshReport();
  }

  Future<void> _refreshReport() async {
    if (!_isEnabled) {
      _report = null;
      _isLoadingReport = false;
      notifyListeners();
      return;
    }
    _isLoadingReport = true;
    notifyListeners();
    _report = await _diagnostics.readReport();
    _isLoadingReport = false;
    notifyListeners();
  }
}
