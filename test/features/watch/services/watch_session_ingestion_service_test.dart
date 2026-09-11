import 'dart:io';

import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/watch/models/watch_session_handoff.dart';
import 'package:endurain/features/watch/services/watch_session_ingestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDirectory;
  late LocalActivityRepository repository;
  late WatchSessionIngestionService service;

  WatchSessionHandoff buildHandoff({
    String sessionId = 'watch_session_1',
    bool isComplete = true,
    WatchSource source = WatchSource.wearOs,
    List<Map<String, Object?>>? points,
    Map<String, Object?> sessionOverrides = const {},
  }) {
    return WatchSessionHandoff.fromJson({
      'version': WatchSessionHandoff.currentPayloadVersion,
      'source': source.name,
      'complete': isComplete,
      'session': {
        'localSessionId': sessionId,
        'activityType': 'run',
        'status': 'completed',
        'startedAt': '2026-06-03T09:00:00.000Z',
        'endedAt': '2026-06-03T09:00:10.000Z',
        'elapsedDurationSeconds': 10,
        ...sessionOverrides,
      },
      'points':
          points ??
          [
            {
              't': '2026-06-03T09:00:00.000Z',
              'lat': 41.0,
              'lon': -8.0,
              'seg': 0,
              'hr': 120,
            },
            {
              't': '2026-06-03T09:00:05.000Z',
              'lat': 41.001,
              'lon': -8.0,
              'seg': 0,
            },
            {
              't': '2026-06-03T09:00:10.000Z',
              'lat': 41.002,
              'lon': -8.0,
              'seg': 1,
            },
          ],
    });
  }

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp('watch_ingest');
    repository = createTestLocalActivityRepository(supportDirectory);
    service = WatchSessionIngestionService(
      repository: repository,
      now: () => DateTime.utc(2026, 6, 3, 10),
    );
  });

  tearDown(() async {
    if (supportDirectory.existsSync()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test('persists a complete session as a pending local activity', () async {
    final result = await service.ingest(buildHandoff());

    expect(result.outcome, WatchIngestionOutcome.ingested);
    final stored = await repository.get(result.localActivityId!);
    expect(stored, isNotNull);
    expect(stored!.activityType, ActivityType.run);
    expect(stored.uploadStatus, LocalActivityUploadStatus.pending);
    expect(stored.pointCount, 3);
    expect(stored.elapsedDurationSeconds, 10);
    final gpx = await repository.readGpxContents(stored);
    // Two segments: the point in segment 1 must not be joined to segment 0.
    expect('<trkseg>'.allMatches(gpx), hasLength(2));
    expect(gpx, contains('<gpxtpx:hr>120</gpxtpx:hr>'));
  });

  test('derives a deterministic id from the source and session id', () {
    final id = WatchSessionIngestionService.localActivityIdFor(
      buildHandoff(sessionId: 'session/../1', source: WatchSource.appleWatch),
    );

    expect(id, 'watch_appleWatch_session____1');
  });

  test('re-ingesting the same session reports a duplicate', () async {
    final first = await service.ingest(buildHandoff());
    final second = await service.ingest(buildHandoff());

    expect(first.outcome, WatchIngestionOutcome.ingested);
    expect(second.outcome, WatchIngestionOutcome.duplicate);
    expect(second.localActivityId, first.localActivityId);
    expect(await repository.count(), 1);
  });

  test('does not ingest an incomplete session', () async {
    final result = await service.ingest(buildHandoff(isComplete: false));

    expect(result.outcome, WatchIngestionOutcome.incomplete);
    expect(result.isAcknowledgeable, isFalse);
  });

  test('reports an empty session without persisting it', () async {
    final result = await service.ingest(buildHandoff(points: const []));

    expect(result.outcome, WatchIngestionOutcome.empty);
    expect(result.isAcknowledgeable, isTrue);
    expect(await repository.count(), 0);
  });

  test('carries the connection binding from the watch session', () async {
    final result = await service.ingest(
      buildHandoff(
        sessionOverrides: const {
          'connectionOrigin': 'https://endurain.example',
          'connectionProfileId': 'profile-1',
        },
      ),
    );

    final stored = await repository.get(result.localActivityId!);
    expect(stored!.connectionOrigin, 'https://endurain.example');
    expect(stored.connectionProfileId, 'profile-1');
  });
}
