import 'dart:async';

import 'package:endurain/app.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // The composition root owns the single production [AppServices] instance and
  // passes it down to the root [App]. Production never routes through the
  // `AppServices.instance` global — that global is only a last-resort fallback
  // for tests that build widgets without an [AppScope] (see `app_scope.dart`).
  // Holding the instance here also keeps the same diagnostics object available
  // to the root-zone error handler below, which runs outside the widget tree.
  final services = AppServices(
    config: const AppConfig(
      healthSyncEnabled: bool.fromEnvironment(
        'ENABLE_HEALTH_SYNC',
        defaultValue: true,
      ),
    ),
  );
  final diagnostics = services.diagnostics;

  final appRunner = runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await diagnostics.initialize();
      diagnostics.recordBreadcrumbSync(DiagnosticsEvents.appStarted);

      // Load the persisted language (BCP 47) before the first frame so the UI
      // starts in the user's chosen locale rather than flashing the system one.
      await services.localeController.load();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        diagnostics.recordFlutterErrorSync(details);
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        diagnostics.recordErrorSync(
          error,
          stackTrace,
          source: DiagnosticsSources.platformDispatcher,
        );
        return false;
      };

      runApp(App(services: services));

      // Reconnect a remembered heart-rate sensor in the background so it is
      // ready before the user starts recording. Touching the coordinator also
      // starts it listening for Bluetooth becoming ready. Best-effort and
      // self-guarded; a no-op when no sensor was ever paired.
      unawaited(services.heartRateSensorService.tryReconnectRemembered());
    },
    (error, stackTrace) {
      diagnostics.recordErrorSync(
        error,
        stackTrace,
        source: DiagnosticsSources.rootZone,
      );
    },
  );
  await appRunner;
}
