import 'dart:async';
import 'dart:io';

import 'package:endurain/app.dart';
import 'package:endurain/app/app_services.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/services/platform/device_info_service.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  // The composition root owns the single production [AppServices] instance and
  // passes it down to the root [App], which exposes it through [AppScope].
  // There is no global instance: widgets obtain services from the scope, and
  // `App` builds its own fallback only when constructed without one (tests).
  // Holding the instance here also keeps the same diagnostics object available
  // to the root-zone error handler below, which runs outside the widget tree.
  final services = AppServices(
    config: AppConfig(
      healthSyncEnabled: const bool.fromEnvironment(
        'ENABLE_HEALTH_SYNC',
        defaultValue: true,
      ),
      // Managed diagnostics DSN, injected at build time by the official CI via
      // `--dart-define=ENDURAIN_CRASH_REPORTING_DSN=...`. Source and F-Droid
      // builds omit it, so no fork points its opt-in crash reports at the
      // Endurain-operated endpoint by default. An empty value means "no managed
      // default", which keeps remote reporting inactive.
      crashReportingDsn: const String.fromEnvironment(
        'ENDURAIN_CRASH_REPORTING_DSN',
      ),
      // Origin of the managed ("Endurain Cloud") service. No managed service
      // exists yet, so every current build leaves this empty and treats every
      // origin as a user-chosen self-hosted instance. Setting it must be paired
      // with the OS-level pins in the Android network security config and the
      // iOS Info.plist.
      cloudBaseUrl: const String.fromEnvironment('ENDURAIN_CLOUD_BASE_URL'),
      allowedTileServerHosts: AppConfig.parseTileServerHostAllowlist(
        const String.fromEnvironment('ENDURAIN_ALLOWED_TILE_HOSTS'),
      ),
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
      final launchContext = await _diagnosticsContext(
        services.packageInfo,
        services.deviceInfo,
      );
      diagnostics
        ..setContext(launchContext)
        ..recordBreadcrumbSync(
          DiagnosticsEvents.appStarted,
          details: {'version': launchContext['appVersion']},
        );

      // Before anything reaches the server: a v0.21 server refuses the tokens
      // of a session stored before its upgrade, and the app then clears it.
      // Remember which pre-v0.21 account it was so its local data can follow
      // the account to its new id at the next sign-in. Never throws; bounded
      // so a stalled keychain cannot keep the app from starting.
      await services.legacyProfileAdoption.captureLegacyHint().timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );

      // Load the persisted language (BCP 47) before the first frame so the UI
      // starts in the user's chosen locale rather than flashing the system one.
      await services.localeController.load();

      // Same for the unit preference, so stats never flash metric before
      // switching to imperial.
      await services.measurementSystemController.load();

      // Load the audio-announcement preference so a recording started before
      // the settings screen is ever opened still uses the user's saved choice.
      await services.audioAnnouncementSettingsController.load();

      // Start remote crash reporting only if the user previously opted in.
      // No-op (and no network) otherwise; the two diagnostics channels are
      // independent. Best-effort and bounded: a failure or stall here (it
      // reads preferences and may start a network transport) must never keep
      // the app from reaching `runApp`.
      try {
        await crashReporting.initializeIfEnabled().timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {}

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
      unawaited(services.reconnectRememberedSensors(withRetries: true));
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

/// The report header for this launch: which build, on which device and OS.
/// Both lookups run at once and are bounded and best-effort, so a slow
/// platform channel cannot delay startup by more than [_contextTimeout].
Future<Map<String, Object?>> _diagnosticsContext(
  PackageInfoService packageInfo,
  DeviceInfoService deviceInfo,
) async {
  final (version, device) = await (
    packageInfo
        .fromPlatform()
        .then<String?>((info) => '${info.version}+${info.buildNumber}')
        .timeout(_contextTimeout)
        .catchError((Object _) => null),
    deviceInfo
        .diagnosticsSummary()
        .timeout(_contextTimeout)
        .catchError((Object _) => const <String, Object?>{}),
  ).wait;
  return {
    'appVersion': version ?? 'unknown',
    'buildMode': kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug',
    'platform': Platform.operatingSystem,
    // Dart's own OS string, kept only when the device lookup failed: on
    // Android it is a kernel version, not the Android release.
    'osVersion': Platform.operatingSystemVersion,
    ...device,
    'launchedAt': DateTime.now().toUtc().toIso8601String(),
  };
}

const Duration _contextTimeout = Duration(seconds: 2);
