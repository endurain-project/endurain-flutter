import 'package:endurain/app/app_infrastructure.dart';
import 'package:endurain/app/modules/activity_module.dart';
import 'package:endurain/features/watch/repositories/watch_ingestion_ledger.dart';
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

  /// Durable record of ingested watch sessions, used for deduplication and
  /// to let Health Sync skip workouts a watch session already covers.
  late final WatchIngestionLedger ledger = WatchIngestionLedger(
    preferences: _infra.preferences,
  );

  late final WatchSessionIngestionService ingestion =
      WatchSessionIngestionService(
        repository: _activity.localActivities,
        ledger: ledger,
        finalizer: _activity.finalizer,
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
  /// Android and iOS use the platform-channel transport, served by the
  /// WatchConnectivity bridge on iOS and the Wearable Data Layer bridge on
  /// Android. An Android build without the Wear OS link
  /// (`-Pendurain.wearable=false`) answers "unsupported", which keeps it inert.
  /// Every other target (desktop, web) gets the inert fallback.
  ///
  /// `flutter test` reports [TargetPlatform.android] by default, so tests get
  /// the platform-channel transport too; with no native handler registered it
  /// is just as inert.
  WatchTransportAdapter createTransportAdapter() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return MethodChannelWatchTransport();
    }
    return const UnsupportedWatchTransport();
  }
}
