import 'dart:async';

import 'package:endurain/app.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // The composition root owns the single production [AppServices] instance and
  // passes it down to the root [App], which exposes it through [AppScope].
  // There is no global instance: widgets obtain services from the scope, and
  // `App` builds its own fallback only when constructed without one (tests).
  // Holding the instance here also keeps the same diagnostics object available
  // to the root-zone error handler below, which runs outside the widget tree.
  final services = AppServices(
    config: const AppConfig(
      healthSyncEnabled: bool.fromEnvironment(
        'ENABLE_HEALTH_SYNC',
        defaultValue: true,
      ),
      // Managed diagnostics DSN, injected at build time by the official CI via
      // `--dart-define=ENDURAIN_CRASH_REPORTING_DSN=...`. Source and F-Droid
      // builds omit it, so no fork points its opt-in crash reports at the
      // Endurain-operated endpoint by default. An empty value means "no managed
      // default", which keeps remote reporting inactive.
      crashReportingDsn: String.fromEnvironment('ENDURAIN_CRASH_REPORTING_DSN'),
    ),
  );
  final diagnostics = services.diagnostics;
  // Opt-in remote crash reporting, independent of local diagnostics. Held here
  // so the root-zone error handler below (which runs outside the widget tree)
  // can forward to it just like it does to diagnostics.
  final crashReporting = services.crashReporting;

  final appRunner = runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await diagnostics.initialize();
      diagnostics.recordBreadcrumbSync(DiagnosticsEvents.appStarted);

      // Load the persisted language (BCP 47) before the first frame so the UI
      // starts in the user's chosen locale rather than flashing the system one.
      await services.localeController.load();

      // Same for the unit preference, so stats never flash metric before
      // switching to imperial.
      await services.measurementSystemController.load();

      // Start remote crash reporting only if the user previously opted in.
      // No-op (and no network) otherwise; the two diagnostics channels are
      // independent.
      await crashReporting.initializeIfEnabled();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        diagnostics.recordFlutterErrorSync(details);
        unawaited(
          crashReporting.recordError(
            details.exception,
            details.stack ?? StackTrace.empty,
            source: DiagnosticsSources.flutter,
          ),
        );
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        diagnostics.recordErrorSync(
          error,
          stackTrace,
          source: DiagnosticsSources.platformDispatcher,
        );
        unawaited(
          crashReporting.recordError(
            error,
            stackTrace,
            source: DiagnosticsSources.platformDispatcher,
          ),
        );
        return false;
      };

      runApp(App(services: services));

      // Reconnect any remembered heart-rate, power, and cadence sensors in the
      // background so they are ready before the user starts recording. Touching
      // each coordinator also starts it listening for Bluetooth becoming ready.
      // Best-effort and self-guarded; a no-op when no sensor was ever paired.
      unawaited(services.reconnectRememberedSensors());
    },
    (error, stackTrace) {
      diagnostics.recordErrorSync(
        error,
        stackTrace,
        source: DiagnosticsSources.rootZone,
      );
      unawaited(
        crashReporting.recordError(
          error,
          stackTrace,
          source: DiagnosticsSources.rootZone,
        ),
      );
    },
  );
  await appRunner;
}
