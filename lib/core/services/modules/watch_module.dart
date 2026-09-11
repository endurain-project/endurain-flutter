import 'package:endurain/core/services/app_infrastructure.dart';
import 'package:endurain/core/services/modules/activity_module.dart';
import 'package:endurain/features/watch/services/watch_companion_service.dart';
import 'package:endurain/features/watch/services/watch_session_ingestion_service.dart';
import 'package:endurain/features/watch/services/watch_transport_adapter.dart';
import 'package:endurain/features/watch/services/watch_transport_channel.dart';
import 'package:flutter/foundation.dart';

/// Wires the companion-watch feature: the platform transport, the idempotent
/// session ingestion, and the app-lifetime coordinator that hands ingested
/// activities to the existing upload queue.
///
/// Depends on [AppInfrastructure] and [ActivityModule]; the watch never talks
/// to the server itself, it only produces activities the phone already knows
/// how to store and upload.
class WatchModule {
  WatchModule({
    required AppInfrastructure infra,
    required ActivityModule activity,
  }) : _infra = infra,
       _activity = activity;

  final AppInfrastructure _infra;
  final ActivityModule _activity;

  late final WatchSessionIngestionService ingestion =
      WatchSessionIngestionService(
        repository: _activity.localActivities,
        diagnostics: _infra.diagnostics,
      );

  /// App-lifetime coordinator. Consumers obtain it from the app scope and must
  /// NOT dispose it.
  late final WatchCompanionService companion = WatchCompanionService(
    transport: createTransportAdapter(),
    ingestionService: ingestion,
    onActivitiesIngested: _activity.uploadQueue.drain,
    diagnostics: _infra.diagnostics,
  );

  /// Builds the watch transport for the current platform.
  ///
  /// Android and iOS use the platform-channel transport, which degrades to
  /// "unsupported" while the native Wear OS / watchOS bridges are not present.
  /// Every other environment (desktop, web, the test host runtime) gets the
  /// inert fallback.
  WatchTransportAdapter createTransportAdapter() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return MethodChannelWatchTransport();
    }
    return const UnsupportedWatchTransport();
  }
}
