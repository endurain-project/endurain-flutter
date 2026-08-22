import 'dart:async';
import 'dart:io';

import 'package:endurain/features/watch/models/watch_link_status.dart';
import 'package:endurain/features/watch/models/watch_session_handoff.dart';
import 'package:endurain/features/watch/models/watch_transport_event.dart';
import 'package:endurain/features/watch/services/watch_companion_service.dart';
import 'package:endurain/features/watch/services/watch_session_ingestion_service.dart';
import 'package:endurain/features/watch/services/watch_transport_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

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

  @override
  Stream<WatchTransportEvent> get events => controller.stream;

  @override
  Future<WatchLinkStatus> linkStatus() async => status;

  @override
  Future<List<WatchSessionHandoff>> drainPendingHandoffs() async {
    drainCount++;
    if (failDrain) {
      throw StateError('drain failed');
    }
    return handoffs;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDirectory;
  late WatchSessionIngestionService ingestion;

  WatchSessionHandoff buildHandoff({
    String sessionId = 'watch_session_1',
    bool isComplete = true,
  }) {
    return WatchSessionHandoff.fromJson({
      'version': WatchSessionHandoff.currentPayloadVersion,
      'source': 'wearOs',
      'complete': isComplete,
      'session': {
        'localSessionId': sessionId,
        'activityType': 'run',
        'status': 'completed',
        'startedAt': '2026-06-03T09:00:00.000Z',
        'endedAt': '2026-06-03T09:00:05.000Z',
      },
      'points': [
        {'t': '2026-06-03T09:00:00.000Z', 'lat': 41.0, 'lon': -8.0, 'seg': 0},
        {'t': '2026-06-03T09:00:05.000Z', 'lat': 41.001, 'lon': -8.0, 'seg': 0},
      ],
    });
  }

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp('watch_companion');
    ingestion = WatchSessionIngestionService(
      repository: createTestLocalActivityRepository(supportDirectory),
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

    expect(summary.skipped, 1);
    expect(summary.ingested, 0);
    expect(transport.acknowledged, isEmpty);
    expect(uploadDrains, 0);
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

  test('concurrent syncs share one drain', () async {
    final transport = FakeWatchTransport(handoffs: [buildHandoff()]);
    final service = WatchCompanionService(
      transport: transport,
      ingestionService: ingestion,
    );

    await Future.wait([
      service.syncPendingSessions(),
      service.syncPendingSessions(),
    ]);

    expect(transport.drainCount, 1);
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
