import 'dart:convert';
import 'dart:io';

import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/watch/models/watch_session_handoff.dart';
import 'package:endurain/features/watch/repositories/watch_ingestion_ledger.dart';
import 'package:endurain/features/watch/services/watch_session_ingestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDirectory;
  late LocalActivityRepository repository;
  late WatchIngestionLedger ledger;
  late WatchSessionIngestionService service;

  WatchSessionHandoff buildHandoff({
    String sessionId = 'watch_session_1',
    bool isComplete = true,
    WatchSource source = WatchSource.wearOs,
    List<Object?>? points,
    Map<String, Object?> sessionOverrides = const {},
    String? healthWorkoutId,
  }) {
    return WatchSessionHandoff.fromJson({
      'version': WatchSessionHandoff.currentPayloadVersion,
      'source': source.name,
      'healthWorkoutId': ?healthWorkoutId,
      'session': {
        'localSessionId': sessionId,
        'activityType': 'run',
        'status': isComplete ? 'completed' : 'recording',
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
    ledger = WatchIngestionLedger(preferences: FakePreferencesStore());
    service = WatchSessionIngestionService(
      repository: repository,
      ledger: ledger,
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

  test('ingests the envelope the Apple Watch app sends', () async {
    // Byte-for-byte what ios/Shared/Watch/WatchHandoffBuilder.swift writes
    // (key order aside); WatchHandoffBuilderTests checks the Swift side of
    // the same shape. Change both together.
    const fromWatch = '''
{"version":1,"source":"appleWatch","healthWorkoutId":"6F1C2B9E-2D4A-4C3B-9E1F-0A7B5C3D2E10",
 "session":{"schemaVersion":3,"localSessionId":"0B8E6C1A-5F2D-4E7B-8A9C-3D1E2F4A5B6C",
  "activityType":"ride","status":"completed","startedAt":"2027-01-15T08:00:00.000Z",
  "endedAt":"2027-01-15T08:01:30.000Z","elapsedDurationSeconds":60,
  "currentSegmentIndex":1,"autoPauseEnabled":false,"autoPauseDelaySeconds":5,
  "pausedAutomatically":false},
 "points":[
  {"t":"2027-01-15T08:00:10.000Z","lat":38.7,"lon":-9.1,"seg":0,"ele":12.5,
   "hAcc":4,"vAcc":3,"head":90,"spd":3.2,"spdAcc":0.5,"hr":151},
  {"t":"2027-01-15T08:01:10.000Z","lat":38.701,"lon":-9.1,"seg":1,"hAcc":5}
 ]}
''';
    final handoff = WatchSessionHandoff.fromJson(
      jsonDecode(fromWatch) as Map<String, dynamic>,
    );

    final result = await service.ingest(handoff);

    expect(result.outcome, WatchIngestionOutcome.ingested);
    expect(handoff.droppedPointCount, 0);
    expect(
      result.localActivityId,
      'watch_appleWatch_0B8E6C1A-5F2D-4E7B-8A9C-3D1E2F4A5B6C',
    );
    final stored = await repository.get(result.localActivityId!);
    expect(stored!.activityType, ActivityType.ride);
    expect(stored.elapsedDurationSeconds, 60);
    expect(stored.pointCount, 2);
    expect(
      await ledger.containsHealthWorkout(
        '6F1C2B9E-2D4A-4C3B-9E1F-0A7B5C3D2E10',
      ),
      isTrue,
    );
    final gpx = await repository.readGpxContents(stored);
    expect('<trkseg>'.allMatches(gpx), hasLength(2));
    expect(gpx, contains('<gpxtpx:hr>151</gpxtpx:hr>'));
  });

  test('ingests the envelope the Wear OS app sends', () async {
    // What android/watch_shared/.../WatchHandoffBuilder.kt writes (org.json
    // output, key order aside); WatchHandoffBuilderTest checks the Kotlin
    // side of the same shape. Change both together.
    const fromWatch = '''
{"version":1,"source":"wearOs",
 "session":{"schemaVersion":3,"localSessionId":"5d0c6b1e-8f3a-4b7c-9e2d-1a4f6c8b0e3d",
  "activityType":"hike","status":"completed","startedAt":"2027-01-15T08:00:00.000Z",
  "endedAt":"2027-01-15T08:01:30.000Z","elapsedDurationSeconds":60,
  "currentSegmentIndex":1,"autoPauseEnabled":false,"autoPauseDelaySeconds":5,
  "pausedAutomatically":false},
 "points":[
  {"t":"2027-01-15T08:00:10.000Z","lat":38.7,"lon":-9.1,"seg":0,"ele":12.5,
   "hAcc":4.0,"vAcc":3.0,"head":90.0,"hr":151},
  {"t":"2027-01-15T08:01:10.000Z","lat":38.701,"lon":-9.1,"seg":1,"hAcc":5.0}
 ]}
''';
    final handoff = WatchSessionHandoff.fromJson(
      jsonDecode(fromWatch) as Map<String, dynamic>,
    );

    final result = await service.ingest(handoff);

    expect(result.outcome, WatchIngestionOutcome.ingested);
    expect(handoff.source, WatchSource.wearOs);
    expect(handoff.healthWorkoutId, isNull);
    expect(
      result.localActivityId,
      'watch_wearOs_5d0c6b1e-8f3a-4b7c-9e2d-1a4f6c8b0e3d',
    );
    final stored = await repository.get(result.localActivityId!);
    expect(stored!.activityType, ActivityType.hike);
    expect(stored.pointCount, 2);
    final gpx = await repository.readGpxContents(stored);
    expect('<trkseg>'.allMatches(gpx), hasLength(2));
  });

  test('derives a deterministic id from the source and session id', () {
    final id = WatchSessionIngestionService.localActivityIdFor(
      buildHandoff(sessionId: 'session/../1', source: WatchSource.appleWatch),
    );

    expect(id, 'watch_appleWatch_session_002f_002e_002e_002f1');
    expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id), isTrue);
  });

  test('keeps a UUID session id readable', () {
    final id = WatchSessionIngestionService.localActivityIdFor(
      buildHandoff(sessionId: '3f2a9c1e-7b4d-4e8a-9f00-1c2d3e4f5a6b'),
    );

    expect(id, 'watch_wearOs_3f2a9c1e-7b4d-4e8a-9f00-1c2d3e4f5a6b');
  });

  test('never maps two distinct session ids to the same id', () {
    String idFor(String sessionId) =>
        WatchSessionIngestionService.localActivityIdFor(
          buildHandoff(sessionId: sessionId),
        );

    expect(idFor('a.b'), isNot(idFor('a_b')));
    expect(idFor('a_b'), isNot(idFor('a_005fb')));
    expect(idFor('a/b'), isNot(idFor('a.b')));
  });

  test(
    'two sessions whose ids differ only in punctuation both ingest',
    () async {
      final first = await service.ingest(buildHandoff(sessionId: 'a.b'));
      final second = await service.ingest(buildHandoff(sessionId: 'a_b'));

      expect(first.outcome, WatchIngestionOutcome.ingested);
      expect(second.outcome, WatchIngestionOutcome.ingested);
      expect(await repository.count(), 2);
    },
  );

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

  test('a re-delivered session stays a duplicate after the local record is '
      'deleted', () async {
    final first = await service.ingest(buildHandoff());
    await repository.delete(first.localActivityId!);

    final second = await service.ingest(buildHandoff());

    expect(second.outcome, WatchIngestionOutcome.duplicate);
    expect(second.isAcknowledgeable, isTrue);
    expect(await repository.count(), 0);
  });

  test('backfills the ledger for a record stored without it', () async {
    final first = await service.ingest(buildHandoff());
    // A fresh ledger simulates a ledger write that never landed.
    final freshLedger = WatchIngestionLedger(
      preferences: FakePreferencesStore(),
    );
    final retry = WatchSessionIngestionService(
      repository: repository,
      ledger: freshLedger,
    );

    final second = await retry.ingest(buildHandoff());

    expect(second.outcome, WatchIngestionOutcome.duplicate);
    expect(await freshLedger.contains(first.localActivityId!), isTrue);
  });

  test('records the health workout id of an ingested session', () async {
    await service.ingest(buildHandoff(healthWorkoutId: 'hk-workout-1'));

    expect(await ledger.containsHealthWorkout('hk-workout-1'), isTrue);
    expect(await ledger.containsHealthWorkout('hk-workout-2'), isFalse);
  });

  test('acknowledges a session that carried nothing at all', () async {
    final result = await service.ingest(
      buildHandoff(
        points: const [],
        sessionOverrides: const {
          'endedAt': '2026-06-03T09:00:00.000Z',
          'elapsedDurationSeconds': 0,
        },
      ),
    );

    expect(result.outcome, WatchIngestionOutcome.empty);
    expect(result.isAcknowledgeable, isTrue);
    expect(await repository.count(), 0);
  });

  test('keeps a session whose points are all unreadable queued', () async {
    final result = await service.ingest(
      buildHandoff(
        points: const [
          {'future_schema': true},
          'not-a-map',
        ],
      ),
    );

    expect(result.outcome, WatchIngestionOutcome.unreadable);
    expect(result.isAcknowledgeable, isFalse);
    expect(await repository.count(), 0);
  });

  test('keeps an indoor session without a route queued', () async {
    final result = await service.ingest(buildHandoff(points: const []));

    expect(result.outcome, WatchIngestionOutcome.noRoute);
    expect(result.isAcknowledgeable, isFalse);
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
