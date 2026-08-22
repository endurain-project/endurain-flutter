import 'dart:async';

import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/watch/models/watch_link_status.dart';
import 'package:endurain/features/watch/models/watch_session_handoff.dart';
import 'package:endurain/features/watch/models/watch_transport_event.dart';
import 'package:endurain/features/watch/services/watch_session_ingestion_service.dart';
import 'package:endurain/features/watch/services/watch_transport_adapter.dart';

/// Summary of one sync pass over the pending watch handoffs.
class WatchSyncSummary {
  const WatchSyncSummary({
    this.ingested = 0,
    this.duplicates = 0,
    this.skipped = 0,
    this.failed = 0,
  });

  final int ingested;
  final int duplicates;
  final int skipped;
  final int failed;

  bool get hasNewActivities => ingested > 0;
}

/// App-lifetime coordinator that pulls finished sessions off a paired watch and
/// feeds them into the phone's existing activity pipeline.
///
/// It owns no UI state and no upload logic of its own: [WatchTransportAdapter]
/// provides the sessions, [WatchSessionIngestionService] persists them, and the
/// injected [onActivitiesIngested] callback (wired to the durable upload queue)
/// takes it from there.
///
/// [syncPendingSessions] is single-flight, so a link-status change, a push
/// event, and an app-resume cannot start overlapping drains.
class WatchCompanionService {
  WatchCompanionService({
    required WatchTransportAdapter transport,
    required WatchSessionIngestionService ingestionService,
    Future<void> Function()? onActivitiesIngested,
    DiagnosticsRecorder? diagnostics,
  }) : _transport = transport,
       _ingestionService = ingestionService,
       _onActivitiesIngested = onActivitiesIngested,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder() {
    _eventSubscription = _transport.events.listen(_handleEvent);
  }

  final WatchTransportAdapter _transport;
  final WatchSessionIngestionService _ingestionService;
  final Future<void> Function()? _onActivitiesIngested;
  final DiagnosticsRecorder _diagnostics;

  StreamSubscription<WatchTransportEvent>? _eventSubscription;
  Future<WatchSyncSummary>? _inFlightSync;
  WatchLinkStatus _linkStatus = WatchLinkStatus.unsupported;
  bool _disposed = false;

  /// Last known reachability of the paired watch.
  WatchLinkStatus get linkStatus => _linkStatus;

  /// Refreshes [linkStatus] from the transport.
  Future<WatchLinkStatus> refreshLinkStatus() async {
    final status = await _transport.linkStatus();
    _linkStatus = status;
    return status;
  }

  /// Drains every pending handoff, persisting each finished watch session as a
  /// local activity and acknowledging the ones that reached a terminal state.
  ///
  /// Never throws: transport failures are reported as a breadcrumb and the
  /// handoffs stay queued for the next pass.
  Future<WatchSyncSummary> syncPendingSessions() {
    return _inFlightSync ??= _runSync().whenComplete(() {
      _inFlightSync = null;
    });
  }

  Future<WatchSyncSummary> _runSync() async {
    if (_disposed) {
      return const WatchSyncSummary();
    }

    _diagnostics.recordBreadcrumbSync(DiagnosticsEvents.watchSyncStarted);
    final handoffs = await _drainHandoffs();
    if (handoffs == null) {
      return const WatchSyncSummary();
    }

    var ingested = 0;
    var duplicates = 0;
    var skipped = 0;
    var failed = 0;
    for (final handoff in handoffs) {
      final result = await _ingestionService.ingest(handoff);
      switch (result.outcome) {
        case WatchIngestionOutcome.ingested:
          ingested++;
        case WatchIngestionOutcome.duplicate:
          duplicates++;
        case WatchIngestionOutcome.empty:
        case WatchIngestionOutcome.incomplete:
          skipped++;
        case WatchIngestionOutcome.failed:
          failed++;
      }
      if (result.isAcknowledgeable) {
        // A failed acknowledgement is harmless: the handoff is re-delivered and
        // the deterministic id makes the next ingestion a duplicate.
        try {
          await _transport.acknowledgeHandoff(handoff.sessionId);
        } catch (_) {
          // Intentionally ignored; the session is already stored locally.
        }
      }
    }

    final summary = WatchSyncSummary(
      ingested: ingested,
      duplicates: duplicates,
      skipped: skipped,
      failed: failed,
    );
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.watchSyncFinished,
      details: {
        'ingested': ingested,
        'duplicates': duplicates,
        'skipped': skipped,
        'failed': failed,
      },
    );

    final onActivitiesIngested = _onActivitiesIngested;
    if (summary.hasNewActivities && onActivitiesIngested != null) {
      await onActivitiesIngested();
    }
    return summary;
  }

  /// Returns `null` when the transport could not be read, so the caller can
  /// leave every handoff queued for the next pass.
  Future<List<WatchSessionHandoff>?> _drainHandoffs() async {
    try {
      return await _transport.drainPendingHandoffs();
    } catch (error) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.watchSyncFailed,
        details: {'type': error.runtimeType.toString()},
      );
      return null;
    }
  }

  void _handleEvent(WatchTransportEvent event) {
    switch (event.type) {
      case WatchTransportEventType.linkStatusChanged:
        final status = event.linkStatus;
        if (status != null) {
          _linkStatus = status;
          if (status.isReachable) {
            unawaited(syncPendingSessions());
          }
        }
      case WatchTransportEventType.handoffAvailable:
        unawaited(syncPendingSessions());
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _transport.dispose();
  }
}
