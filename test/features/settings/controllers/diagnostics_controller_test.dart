import 'package:endurain/core/services/crash_reporting_service.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/settings/controllers/diagnostics_controller.dart';
import 'package:endurain/features/settings/repositories/crash_reporting_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_crash_reporter.dart';
import '../../../helpers/fake_preferences_store.dart';
import '../../../helpers/inert_crash_reporting.dart';

void main() {
  DiagnosticsReport reportWithOneEvent() {
    return DiagnosticsReport.fromPayload({
      'schemaVersion': 1,
      'app': 'Endurain',
      'lastUpdatedAt': '2026-06-01T12:30:00Z',
      'breadcrumbs': [
        {'at': '2026-06-01T12:29:00Z', 'event': DiagnosticsEvents.appStarted},
      ],
      'errors': <Object>[],
    });
  }

  // Wraps a diagnostics store with an inert crash-reporting service so the
  // existing tests exercise only the local diagnostics path.
  DiagnosticsController makeController(DiagnosticsStore store) {
    return DiagnosticsController(
      diagnostics: store,
      crashReporting: inertCrashReportingService(),
    );
  }

  group('DiagnosticsController', () {
    test('reflects the store enabled flag on construction', () {
      final enabled = makeController(_FakeDiagnosticsStore(enabled: true));
      addTearDown(enabled.dispose);
      final disabled = makeController(_FakeDiagnosticsStore());
      addTearDown(disabled.dispose);

      expect(enabled.isEnabled, isTrue);
      expect(disabled.isEnabled, isFalse);
    });

    test('load reads the report and toggles the loading flag', () async {
      final report = reportWithOneEvent();
      final controller = makeController(
        _FakeDiagnosticsStore(enabled: true, report: report),
      );
      addTearDown(controller.dispose);
      final loadingStates = <bool>[];
      controller.addListener(
        () => loadingStates.add(controller.isLoadingReport),
      );

      await controller.load();

      expect(loadingStates, [true, false]);
      expect(controller.isLoadingReport, isFalse);
      expect(controller.report, same(report));
    });

    test('load does not read a report while disabled', () async {
      final store = _FakeDiagnosticsStore(report: reportWithOneEvent());
      final controller = makeController(store);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.report, isNull);
      expect(controller.isLoadingReport, isFalse);
      expect(store.readReportCallCount, 0);
    });

    test(
      'load initializes the store so a persisted opt-in survives restart',
      () async {
        // Models a store whose enabled flag lives on disk but has not been
        // read yet: isEnabled stays false until initialize() runs, exactly
        // like DiagnosticsService on a fresh app launch.
        final store = _LazyDiagnosticsStore(report: reportWithOneEvent());
        final controller = makeController(store);
        addTearDown(controller.dispose);

        // The constructor reads isEnabled before initialize(), so it starts
        // off even though collection was enabled in a previous session.
        expect(controller.isEnabled, isFalse);

        await controller.load();

        expect(store.initializeCallCount, greaterThanOrEqualTo(1));
        expect(controller.isEnabled, isTrue);
        expect(controller.report, same(store.report));
      },
    );

    test('setEnabled(true) enables collection and loads the report', () async {
      final report = reportWithOneEvent();
      final store = _FakeDiagnosticsStore(report: report);
      final controller = makeController(store);
      addTearDown(controller.dispose);

      await controller.setEnabled(true);

      expect(store.lastSetEnabled, isTrue);
      expect(controller.isEnabled, isTrue);
      expect(controller.report, same(report));
    });

    test(
      'setEnabled(false) disables collection and clears the report',
      () async {
        final store = _FakeDiagnosticsStore(
          enabled: true,
          report: reportWithOneEvent(),
        );
        final controller = makeController(store);
        addTearDown(controller.dispose);
        await controller.load();
        expect(controller.report, isNotNull);

        await controller.setEnabled(false);

        expect(store.lastSetEnabled, isFalse);
        expect(controller.isEnabled, isFalse);
        expect(controller.report, isNull);
      },
    );

    test('clearReport clears the store and refreshes the view', () async {
      final store = _FakeDiagnosticsStore(
        enabled: true,
        report: reportWithOneEvent(),
      );
      final controller = makeController(store);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.clearReport();

      expect(store.clearReportCallCount, 1);
      // The store re-read the report after clearing to refresh the view.
      expect(store.readReportCallCount, greaterThanOrEqualTo(2));
    });
  });

  group('DiagnosticsController remote crash reporting', () {
    const usableDsn = 'https://public-key@diagnostics.endurain.com/1';

    DiagnosticsController controllerWith(
      FakeCrashReporter reporter, {
      String? defaultDsn,
    }) {
      return DiagnosticsController(
        diagnostics: _FakeDiagnosticsStore(),
        crashReporting: CrashReportingService(
          reporter: reporter,
          settings: CrashReportingSettingsRepository(
            preferences: FakePreferencesStore(),
          ),
          defaultDsn: defaultDsn,
        ),
      );
    }

    test('is off and inactive by default', () async {
      final controller = controllerWith(
        FakeCrashReporter(),
        defaultDsn: usableDsn,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.crashReportingEnabled, isFalse);
      expect(controller.crashReportingActive, isFalse);
    });

    test('enabling with a usable default DSN activates reporting', () async {
      final reporter = FakeCrashReporter();
      final controller = controllerWith(reporter, defaultDsn: usableDsn);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.setCrashReportingEnabled(true);

      expect(controller.crashReportingEnabled, isTrue);
      expect(controller.crashReportingActive, isTrue);
      expect(reporter.starts.single.dsn, usableDsn);
    });

    test('enabling without a usable DSN stays inactive', () async {
      final reporter = FakeCrashReporter();
      final controller = controllerWith(reporter);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.setCrashReportingEnabled(true);

      expect(controller.crashReportingEnabled, isTrue);
      expect(controller.crashReportingHasUsableServer, isFalse);
      expect(controller.crashReportingActive, isFalse);
      expect(reporter.starts, isEmpty);
    });
  });
}

class _FakeDiagnosticsStore implements DiagnosticsStore {
  _FakeDiagnosticsStore({this.report, bool enabled = false})
    : _enabled = enabled;

  final DiagnosticsReport? report;
  bool _enabled;
  bool? lastSetEnabled;
  int clearReportCallCount = 0;
  int readReportCallCount = 0;

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    lastSetEnabled = enabled;
    _enabled = enabled;
  }

  @override
  Future<void> clearReport() async {
    clearReportCallCount++;
  }

  @override
  Future<DiagnosticsReport?> readReport() async {
    readReportCallCount++;
    return report;
  }

  @override
  Future<String?> readReportText() async => report?.rawText;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> flush() async {}

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

  @override
  void recordFlutterErrorSync(FlutterErrorDetails details) {}
}

/// A store that only exposes the enabled flag after [initialize] runs, mirroring
/// [DiagnosticsService] reading its persisted opt-in from disk on launch.
class _LazyDiagnosticsStore implements DiagnosticsStore {
  _LazyDiagnosticsStore({this.report});

  final DiagnosticsReport? report;
  bool _enabled = false;
  bool _initialized = false;
  int initializeCallCount = 0;

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    if (_initialized) {
      return;
    }
    _initialized = true;
    // The persisted opt-in only becomes visible once the store is initialized.
    _enabled = true;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
  }

  @override
  Future<void> clearReport() async {}

  @override
  Future<DiagnosticsReport?> readReport() async => report;

  @override
  Future<String?> readReportText() async => report?.rawText;

  @override
  Future<void> flush() async {}

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

  @override
  void recordFlutterErrorSync(FlutterErrorDetails details) {}
}
