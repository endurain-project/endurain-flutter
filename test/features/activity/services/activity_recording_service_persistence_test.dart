import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/services/activity_recording_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_active_activity_store.dart';
import '../../../helpers/recording_location_platform_adapter.dart';

void main() {
  group('ActivityRecordingService durable persistence', () {
    late RecordingLocationPlatformAdapter adapter;
    late InMemoryActiveActivityStore store;

    ActivityRecordingService buildService() {
      return ActivityRecordingService(
        now: () => DateTime.utc(2026, 6, 3, 9),
        locationService: LocationService(platformAdapter: adapter),
        activeStore: store,
        sessionIdProvider: () => 'session_1',
      );
    }

    setUp(() {
      adapter = RecordingLocationPlatformAdapter();
      store = InMemoryActiveActivityStore();
    });

    test('persists session and points while recording', () async {
      final service = buildService();
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      await pumpEventQueue();
      expect(store.session, isNotNull);
      expect(store.session!.status, ActiveActivityStatus.recording);
      expect(store.clearCount, 1);

      adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
      await pumpEventQueue();

      expect(store.points, hasLength(1));
      expect(store.points.single.latitude, 41.1);
      expect(store.points.single.segmentIndex, 0);
    });

    test('persists a new segment index after resume', () async {
      final service = buildService();
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
      await pumpEventQueue();
      await service.pause();
      await service.resume();
      adapter.addPosition(recordingPosition(latitude: 41.2, longitude: -8.7));
      await pumpEventQueue();

      expect(store.points, hasLength(2));
      expect(store.points.first.segmentIndex, 0);
      expect(store.points.last.segmentIndex, 1);
    });

    test('completes the session on stop', () async {
      final service = buildService();
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      adapter.addPosition(recordingPosition());
      await pumpEventQueue();
      await service.stop();
      await pumpEventQueue();

      expect(store.completeCount, 1);
      expect(store.session!.status, ActiveActivityStatus.completed);
    });

    test('clears the store on discard', () async {
      final service = buildService();
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      adapter.addPosition(recordingPosition());
      await pumpEventQueue();
      await service.discard();
      await pumpEventQueue();

      expect(store.session, isNull);
      expect(store.points, isEmpty);
    });

    group('recoverActiveSession', () {
      ActiveActivitySession storedSession(ActiveActivityStatus status) {
        return ActiveActivitySession(
          localSessionId: 'session_1',
          activityType: ActivityType.ride,
          status: status,
          startedAt: DateTime.utc(2026, 6, 3, 9),
          elapsedDurationSeconds: 120,
        );
      }

      test('returns false when no session is stored', () async {
        final service = buildService();
        addTearDown(service.dispose);

        expect(await service.recoverActiveSession(), isFalse);
        expect(service.state.status, ActivityRecordingStatus.idle);
      });

      test(
        'recovers a paused session with points as a paused recording',
        () async {
          store.session = storedSession(ActiveActivityStatus.paused);
          await store.appendPoints([
            _point(segmentIndex: 0, latitude: 41.0),
            _point(segmentIndex: 0, latitude: 41.1),
            _point(segmentIndex: 1, latitude: 41.2),
          ]);
          final service = buildService();
          addTearDown(service.dispose);

          final recovered = await service.recoverActiveSession();

          expect(recovered, isTrue);
          expect(service.state.status, ActivityRecordingStatus.paused);
          expect(service.state.activityType, ActivityType.ride);
          expect(service.state.elapsedDurationSeconds, 120);
          expect(service.state.points, hasLength(3));
          expect(service.state.segments, hasLength(2));
        },
      );

      test('recovers a recording session as paused', () async {
        store.session = storedSession(ActiveActivityStatus.recording);
        await store.appendPoints([_point(segmentIndex: 0, latitude: 41.0)]);
        final service = buildService();
        addTearDown(service.dispose);

        final recovered = await service.recoverActiveSession();

        expect(recovered, isTrue);
        expect(service.state.status, ActivityRecordingStatus.paused);
      });

      test('clears and returns false for an empty-point session', () async {
        store.session = storedSession(ActiveActivityStatus.paused);
        final service = buildService();
        addTearDown(service.dispose);

        final recovered = await service.recoverActiveSession();

        expect(recovered, isFalse);
        expect(store.session, isNull);
      });

      test('returns false for a completed (non-active) session', () async {
        store.session = storedSession(ActiveActivityStatus.completed);
        final service = buildService();
        addTearDown(service.dispose);

        expect(await service.recoverActiveSession(), isFalse);
      });
    });
  });
}

RecordedActivityPoint _point({
  required int segmentIndex,
  required double latitude,
}) {
  return RecordedActivityPoint(
    timestamp: DateTime.utc(2026, 6, 3, 9),
    latitude: latitude,
    longitude: -8,
    segmentIndex: segmentIndex,
  );
}
