import 'dart:async';
import 'dart:io';

import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/features/watch/models/watch_link_status.dart';
import 'package:endurain/features/watch/models/watch_session_handoff.dart';
import 'package:endurain/features/watch/models/watch_transport_event.dart';
import 'package:endurain/features/watch/repositories/watch_ingestion_ledger.dart';
import 'package:endurain/features/watch/services/watch_companion_service.dart';
import 'package:endurain/features/watch/services/watch_session_ingestion_service.dart';
import 'package:endurain/features/watch/services/watch_transport_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../../../helpers/sqlite_local_activity_repository.dart';

/// In-memory [WatchTransportAdapter] that records acknowledgements and lets a
/// test push transport events.
class FakeWatchTransport implements WatchTransportAdapter {
  FakeWatchTransport({
    this.handoffs = const [],
    this.status = WatchLinkStatus.connected,
    this.failDrain = false,
  });

  final controller = StreamController<WatchTransportEvent>.broadcast();
  List<WatchSessionHandoff> handoffs;
  WatchLinkStatus status;
  bool failDrain;

  final List<String> acknowledged = <String>[];
  int drainCount = 0;
  bool disposed = false;

  /// When set, each drain waits on it before answering, so a test can make a
  /// request arrive while a drain is in flight.
  Completer<void>? drainGate;

  @override
  Stream<WatchTransportEvent> get events => controller.stream;

  @override
  Future<WatchLinkStatus> linkStatus() async => status;

  @override
  Future<List<WatchSessionHandoff>> drainPendingHandoffs() async {
    drainCount++;
    final snapshot = handoffs;
    final gate = drainGate;
    if (gate != null) {
      await gate.future;
    }
    if (failDrain) {
      throw StateError('drain failed');
    }
    return snapshot;
  }

  @override
  Future<void> acknowledgeHandoff(String sessionId) async {
    acknowledged.add(sessionId);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await controller.close();
  }
}

class RecordingDiagnostics implements DiagnosticsRecorder {
  final List<String> events = <String>[];

  @override
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  }) {
    events.add(event);
  }

  @override
  void recordErrorSync(
    Object error,
    StackTrace stackTrace, {
    String source = DiagnosticsSources.uncaught,
  }) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDirectory;
  late WatchSessionIngestionService ingestion;

  WatchSessionHandoff buildHandoff({
    String sessionId = 'watch_session_1',
    bool isComplete = true,
    List<Object?>? points,
  }) {
    return WatchSessionHandoff.fromJson({
      'version': WatchSessionHandoff.currentPayloadVersion,
      'source': 'wearOs',
      'session': {
        'localSessionId': sessionId,
        'activityType': 'run',
        'status': isComplete ? 'completed' : 'recording',
        'startedAt': '2026-06-03T09:00:00.000Z',
        'endedAt': '2026-06-03T09:00:05.000Z',
      },
      'points':
          points ??
          [
            {
              't': '2026-06-03T09:00:00.000Z',
              'lat': 41.0,
              'lon': -8.0,
              'seg': 0,
            },
            {
              't': '2026-06-03T09:00:05.000Z',
              'lat': 41.001,
              'lon': -8.0,
              'seg': 0,
            },
          ],
    });
  }

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp('watch_companion');
    ingestion = WatchSessionIngestionService(
      repository: createTestLocalActivityRepository(supportDirectory),
      ledger: WatchIngestionLedger(preferences: FakePreferencesStore()),
    );
  });

  tearDown(() async {
    if (supportDirectory.existsSync()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test('ingests pending sessions and acknowledges them', () async {
    final transport = FakeWatchTransport(handoffs: [buildHandoff()]);
    var uploadDrains = 0;
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
      onActivitiesIngested: () async => uploadDrains++,
    );

    final summary = await service.syncPendingSessions();

    expect(summary.ingested, 1);
    expect(summary.failed, 0);
    expect(transport.acknowledged, ['watch_session_1']);
    expect(uploadDrains, 1);
    await service.dispose();
  });

  test('does not acknowledge an incomplete session', () async {
    final transport = FakeWatchTransport(
      handoffs: [buildHandoff(isComplete: false)],
    );
    var uploadDrains = 0;
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
      onActivitiesIngested: () async => uploadDrains++,
    );

    final summary = await service.syncPendingSessions();

    expect(summary.deferred, 1);
    expect(summary.ingested, 0);
    expect(transport.acknowledged, isEmpty);
    expect(uploadDrains, 0);
    await service.dispose();
  });

  test('does not acknowledge sessions it cannot store yet', () async {
    final transport = FakeWatchTransport(
      handoffs: [
        // Points this app version cannot read.
        buildHandoff(
          sessionId: 'unreadable',
          points: const [
            {'future_schema': true},
          ],
        ),
        // An indoor workout: duration but no route.
        buildHandoff(sessionId: 'indoor', points: const []),
      ],
    );
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    final summary = await service.syncPendingSessions();

    expect(summary.deferred, 2);
    expect(summary.skipped, 0);
    expect(transport.acknowledged, isEmpty);
    await service.dispose();
  });

  test('records no breadcrumbs when nothing is pending', () async {
    final diagnostics = RecordingDiagnostics();
    final service = WatchCompanionService(
      transport: FakeWatchTransport(),
      ingestionService: ingestion,
      diagnostics: diagnostics,
    );

    await service.syncPendingSessions();

    expect(diagnostics.events, isEmpty);
    await service.dispose();
  });

  test('records sync breadcrumbs when sessions are pending', () async {
    final diagnostics = RecordingDiagnostics();
    final service = WatchCompanionService(
      transport: FakeWatchTransport(handoffs: [buildHandoff()]),
      ingestionService: ingestion,
      diagnostics: diagnostics,
    );

    await service.syncPendingSessions();

    expect(
      diagnostics.events,
      containsAllInOrder([
        DiagnosticsEvents.watchSyncStarted,
        DiagnosticsEvents.watchSyncFinished,
      ]),
    );
    await service.dispose();
  });

  test('re-delivery of an ingested session is a duplicate', () async {
    final transport = FakeWatchTransport(handoffs: [buildHandoff()]);
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    await service.syncPendingSessions();
    final summary = await service.syncPendingSessions();

    expect(summary.ingested, 0);
    expect(summary.duplicates, 1);
    expect(transport.acknowledged, ['watch_session_1', 'watch_session_1']);
    await service.dispose();
  });

  test('an upload-queue failure does not escape the sync', () async {
    final transport = FakeWatchTransport(handoffs: [buildHandoff()]);
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
      onActivitiesIngested: () async => throw StateError('upload failed'),
    );

    final summary = await service.syncPendingSessions();

    expect(summary.ingested, 1);
    expect(transport.acknowledged, ['watch_session_1']);
    await service.dispose();
  });

  test('a transport event error does not escape', () async {
    final transport = FakeWatchTransport();
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    transport.controller.addError(StateError('native failure'));
    await pumpEventQueue();

    expect(transport.drainCount, 0);
    await service.dispose();
  });

  test('a transport failure leaves handoffs queued', () async {
    final transport = FakeWatchTransport(
      handoffs: [buildHandoff()],
      failDrain: true,
    );
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    final summary = await service.syncPendingSessions();

    expect(summary.ingested, 0);
    expect(transport.acknowledged, isEmpty);
    await service.dispose();
  });

  test('concurrent syncs share one run with a single follow-up pass', () async {
    final transport = FakeWatchTransport(handoffs: [buildHandoff()]);
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    final first = service.syncPendingSessions();
    final second = service.syncPendingSessions();
    final third = service.syncPendingSessions();
    expect(identical(first, second), isTrue);
    expect(identical(first, third), isTrue);

    final summary = await first;

    // The initial pass plus exactly one follow-up, however many requests
    // arrived while it ran. The follow-up sees the same session as a
    // duplicate, never a second activity.
    expect(transport.drainCount, 2);
    expect(summary.ingested, 1);
    expect(summary.duplicates, 1);
    await service.dispose();
  });

  test('a request during a drain schedules a follow-up pass', () async {
    final gate = Completer<void>();
    final transport = FakeWatchTransport()..drainGate = gate;
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    final first = service.syncPendingSessions();
    await pumpEventQueue();
    // The watch queues a session after the running pass read the list.
    transport
      ..handoffs = [buildHandoff()]
      ..drainGate = null;
    transport.controller.add(const WatchTransportEvent.handoffAvailable());
    await pumpEventQueue();
    gate.complete();

    final summary = await first;

    expect(transport.drainCount, 2);
    expect(summary.ingested, 1);
    expect(transport.acknowledged, ['watch_session_1']);
    await service.dispose();
  });

  test('a handoff-available event triggers a sync', () async {
    final transport = FakeWatchTransport(handoffs: [buildHandoff()]);
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    transport.controller.add(const WatchTransportEvent.handoffAvailable());
    await pumpEventQueue();

    expect(transport.drainCount, 1);
    expect(transport.acknowledged, ['watch_session_1']);
    await service.dispose();
  });

  test('becoming reachable syncs and updates the link status', () async {
    final transport = FakeWatchTransport(handoffs: [buildHandoff()]);
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    transport.controller.add(
      const WatchTransportEvent.linkStatusChanged(WatchLinkStatus.connected),
    );
    await pumpEventQueue();

    expect(service.linkStatus, WatchLinkStatus.connected);
    expect(transport.drainCount, 1);
    await service.dispose();
  });

  test('an unreachable link does not trigger a sync', () async {
    final transport = FakeWatchTransport(handoffs: [buildHandoff()]);
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    transport.controller.add(
      const WatchTransportEvent.linkStatusChanged(WatchLinkStatus.disconnected),
    );
    await pumpEventQueue();

    expect(service.linkStatus, WatchLinkStatus.disconnected);
    expect(transport.drainCount, 0);
    await service.dispose();
  });

  test('dispose stops listening and releases the transport', () async {
    final transport = FakeWatchTransport(handoffs: [buildHandoff()]);
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    await service.dispose();

    expect(transport.disposed, isTrue);
    expect(await service.syncPendingSessions(), isA<WatchSyncSummary>());
    expect(transport.drainCount, 0);
  });

  test('refreshLinkStatus reads the transport', () async {
    final transport = FakeWatchTransport(status: WatchLinkStatus.unpaired);
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    expect(await service.refreshLinkStatus(), WatchLinkStatus.unpaired);
    expect(service.linkStatus, WatchLinkStatus.unpaired);
    await service.dispose();
  });

  test('the unsupported transport is inert', () async {
    const transport = UnsupportedWatchTransport();

    expect(await transport.linkStatus(), WatchLinkStatus.unsupported);
    expect(await transport.drainPendingHandoffs(), isEmpty);
    await transport.acknowledgeHandoff('session_1');
    await transport.dispose();
  });
}
