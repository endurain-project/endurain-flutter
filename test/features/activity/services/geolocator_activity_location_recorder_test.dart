import 'dart:async';

import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/repositories/active_activity_store.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/geolocator_activity_location_recorder.dart';
import 'package:endurain/features/activity/services/movement_auto_pause_detector.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/recording_location_platform_adapter.dart';

class _InMemoryActiveStore implements ActiveActivityStore {
  _InMemoryActiveStore({this.appendGate});

  final Completer<void>? appendGate;
  ActiveActivitySession? session;
  final List<RecordedActivityPoint> points = [];
  int clearCount = 0;
  int activeAppends = 0;
  int maxActiveAppends = 0;

  @override
  Future<void> appendPoints(List<RecordedActivityPoint> newPoints) async {
    activeAppends += 1;
    if (activeAppends > maxActiveAppends) {
      maxActiveAppends = activeAppends;
    }
    try {
      await appendGate?.future;
      points.addAll(newPoints);
    } finally {
      activeAppends -= 1;
    }
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    session = null;
    points.clear();
  }

  @override
  Future<void> complete(ActiveActivitySession value) async {
    session = value;
  }

  @override
  Future<ActiveActivitySession?> loadSession() async => session;

  @override
  Future<int> pointCount() async => points.length;

  @override
  Future<List<RecordedActivityPoint>> readPoints({int sinceOffset = 0}) async {
    return points.sublist(sinceOffset.clamp(0, points.length));
  }

  @override
  Future<void> replacePoints(List<RecordedActivityPoint> value) async {
    points
      ..clear()
      ..addAll(value);
  }

  @override
  Future<void> saveSession(ActiveActivitySession value) async {
    session = value;
  }
}

void main() {
  group('GeolocatorActivityLocationRecorder', () {
    late RecordingLocationPlatformAdapter adapter;
    late _InMemoryActiveStore store;
    late _FakeDiagnosticsRecorder diagnostics;
    late GeolocatorActivityLocationRecorder recorder;
    late DateTime now;

    setUp(() {
      now = DateTime.utc(2026, 6, 3, 9);
      adapter = RecordingLocationPlatformAdapter();
      store = _InMemoryActiveStore();
      diagnostics = _FakeDiagnosticsRecorder();
      recorder = GeolocatorActivityLocationRecorder(
        store: store,
        locationService: LocationService(platformAdapter: adapter),
        diagnostics: diagnostics,
        now: () => now,
      );
    });

    tearDown(() => recorder.dispose());

    ActivityRecorderStartRequest request({
      MovementAutoPauseConfig autoPauseConfig = const MovementAutoPauseConfig(),
    }) {
      return ActivityRecorderStartRequest(
        localSessionId: 'session_1',
        activityType: ActivityType.run,
        startedAt: DateTime.utc(2026, 6, 3, 9),
        autoPauseConfig: autoPauseConfig,
      );
    }

    test('persists points before emitting them', () async {
      final events = <ActivityRecorderEvent>[];
      final subscription = recorder.events.listen(events.add);
      addTearDown(subscription.cancel);

      await recorder.start(request());
      expect(store.session, isNotNull);
      expect(store.clearCount, 0);

      adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
      await pumpEventQueue();

      expect(store.points, hasLength(1));
      expect(store.points.single.latitude, 41.1);
      final batch = events.firstWhere(
        (event) => event.type == ActivityRecorderEventType.pointBatchAvailable,
      );
      expect(batch.points.single.latitude, 41.1);
    });

    test('rejects start without clearing an existing session', () async {
      store.session = ActiveActivitySession(
        localSessionId: 'existing',
        activityType: ActivityType.ride,
        status: ActiveActivityStatus.completed,
        startedAt: DateTime.utc(2026, 6, 3, 8),
      );

      await expectLater(recorder.start(request()), throwsStateError);

      expect(store.session?.localSessionId, 'existing');
      expect(store.clearCount, 0);
    });

    test(
      'keeps distance-filtered updates when auto-pause is disabled',
      () async {
        await recorder.start(request());

        expect(
          adapter.lastPositionStreamSettings?.distanceFilter,
          LocationDistanceFilters.recordingMeters,
        );
      },
    );

    test(
      'drops low-accuracy fixes instead of recording ghost points',
      () async {
        await recorder.start(request());
        adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
        await pumpEventQueue();

        // A coarse fix far off the track (e.g. network-provider triangulation)
        // must be rejected rather than persisted.
        adapter.addPosition(
          recordingPosition(latitude: 42.5, longitude: -9.9, accuracy: 1500),
        );
        await pumpEventQueue();

        expect(store.points, hasLength(1));
        expect(store.points.single.latitude, 41.1);
      },
    );

    test('starts a new segment after resume', () async {
      await recorder.start(request());
      adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
      await pumpEventQueue();
      await recorder.pause();
      await recorder.resume();
      adapter.addPosition(recordingPosition(latitude: 41.2, longitude: -8.7));
      await pumpEventQueue();

      expect(store.points, hasLength(2));
      expect(store.points.first.segmentIndex, 0);
      expect(store.points.last.segmentIndex, 1);
    });

    group('auto-pause', () {
      const config = MovementAutoPauseConfig(
        enabled: true,
        pauseDelay: Duration(seconds: 5),
      );
      final startedAt = DateTime.utc(2026, 6, 3, 9);

      ActivityRecorderStartRequest autoPauseRequest() {
        return ActivityRecorderStartRequest(
          localSessionId: 'session_1',
          activityType: ActivityType.run,
          startedAt: startedAt,
          autoPauseConfig: config,
        );
      }

      test('requests unfiltered updates so stillness can trigger', () async {
        await recorder.start(autoPauseRequest());

        expect(
          adapter.lastPositionStreamSettings?.distanceFilter,
          LocationDistanceFilters.autoPauseMeters,
        );
      });

      test('auto-pauses after stillness persists, without cancelling the '
          'position stream', () async {
        final events = <ActivityRecorderEvent>[];
        final subscription = recorder.events.listen(events.add);
        addTearDown(subscription.cancel);

        await recorder.start(autoPauseRequest());
        adapter.addPosition(
          recordingPosition(
            latitude: 41.1,
            longitude: -8.6,
            timestamp: startedAt,
            speed: 0,
          ),
        );
        await pumpEventQueue();
        adapter.addPosition(
          recordingPosition(
            latitude: 41.1,
            longitude: -8.6,
            timestamp: startedAt.add(const Duration(seconds: 5)),
            speed: 0,
          ),
        );
        await pumpEventQueue();

        expect(store.session?.status, ActiveActivityStatus.paused);
        expect(store.session?.pausedAutomatically, isTrue);
        expect(store.session?.elapsedDurationSeconds, 5);
        // The stillness fix that crossed the delay is not itself recorded.
        expect(store.points, hasLength(1));
        expect(
          events.map((event) => event.type),
          contains(ActivityRecorderEventType.autoPaused),
        );
        // Auto-pause must keep monitoring location (unlike a manual pause),
        // so the stream subscription is never cancelled.
        expect(adapter.cancelCount, 0);
      });

      test('auto-resumes after enough consecutive movement and starts a new '
          'segment', () async {
        await recorder.start(autoPauseRequest());
        adapter.addPosition(
          recordingPosition(
            latitude: 41.1,
            longitude: -8.6,
            timestamp: startedAt,
            speed: 0,
          ),
        );
        await pumpEventQueue();
        adapter.addPosition(
          recordingPosition(
            latitude: 41.1,
            longitude: -8.6,
            timestamp: startedAt.add(const Duration(seconds: 5)),
            speed: 0,
          ),
        );
        await pumpEventQueue();
        expect(store.session?.status, ActiveActivityStatus.paused);

        // Two consecutive moving samples are not enough (hysteresis needs
        // three by default): the recording must stay auto-paused.
        adapter.addPosition(
          recordingPosition(
            latitude: 41.15,
            longitude: -8.65,
            timestamp: startedAt.add(const Duration(seconds: 6)),
            speed: 2,
          ),
        );
        await pumpEventQueue();
        adapter.addPosition(
          recordingPosition(
            latitude: 41.16,
            longitude: -8.66,
            timestamp: startedAt.add(const Duration(seconds: 7)),
            speed: 2,
          ),
        );
        await pumpEventQueue();
        expect(store.session?.status, ActiveActivityStatus.paused);
        expect(store.points, hasLength(1));

        final events = <ActivityRecorderEvent>[];
        final subscription = recorder.events.listen(events.add);
        addTearDown(subscription.cancel);

        adapter.addPosition(
          recordingPosition(
            latitude: 41.17,
            longitude: -8.67,
            timestamp: startedAt.add(const Duration(seconds: 8)),
            speed: 2,
          ),
        );
        await pumpEventQueue();

        expect(store.session?.status, ActiveActivityStatus.recording);
        expect(store.session?.pausedAutomatically, isFalse);
        expect(
          events.map((event) => event.type),
          contains(ActivityRecorderEventType.autoResumed),
        );
        // Only the fix that triggered the resume starts the new segment.
        expect(store.points, hasLength(2));
        expect(store.points.first.segmentIndex, 0);
        expect(store.points.last.segmentIndex, 1);
      });

      test('a manual pause is never auto-resumed by movement', () async {
        await recorder.start(autoPauseRequest());
        adapter.addPosition(
          recordingPosition(latitude: 41.1, longitude: -8.6, speed: 0),
        );
        await pumpEventQueue();

        await recorder.pause();
        expect(store.session?.status, ActiveActivityStatus.paused);
        expect(store.session?.pausedAutomatically, isFalse);
        // A manual pause stops the position stream entirely: further
        // positions physically cannot reach the detector, so the recording
        // can never auto-resume on its own.
        expect(adapter.cancelCount, 1);
      });
    });

    test('serializes rapid position events before segment decisions', () async {
      final appendGate = Completer<void>();
      await recorder.dispose();
      store = _InMemoryActiveStore(appendGate: appendGate);
      recorder = GeolocatorActivityLocationRecorder(
        store: store,
        locationService: LocationService(platformAdapter: adapter),
        diagnostics: diagnostics,
        now: () => now,
      );

      await recorder.start(request());
      adapter.addPosition(
        recordingPosition(latitude: 41.1, longitude: -8.6, timestamp: now),
      );
      adapter.addPosition(
        recordingPosition(
          latitude: 41.2,
          longitude: -8.7,
          timestamp: now.add(const Duration(minutes: 2)),
        ),
      );
      await pumpEventQueue();

      expect(store.activeAppends, 1);
      expect(store.maxActiveAppends, 1);

      appendGate.complete();
      await pumpEventQueue();

      expect(store.points, hasLength(2));
      expect(store.points.first.segmentIndex, 0);
      expect(store.points.last.segmentIndex, 1);
      expect(store.maxActiveAppends, 1);
    });

    test('stop completes the stored session', () async {
      await recorder.start(request());
      adapter.addPosition(recordingPosition());
      await pumpEventQueue();
      await recorder.stop();

      expect(store.session!.status, ActiveActivityStatus.completed);
    });

    test('discard clears the store', () async {
      await recorder.start(request());
      await recorder.discard();

      expect(store.session, isNull);
      expect(store.points, isEmpty);
    });

    test('recoverActiveSession returns the persisted session', () async {
      store.session = ActiveActivitySession(
        localSessionId: 'session_1',
        activityType: ActivityType.run,
        status: ActiveActivityStatus.paused,
        startedAt: DateTime.utc(2026, 6, 3, 9),
      );

      final recovered = await recorder.recoverActiveSession();
      expect(recovered, isNotNull);
      expect(recovered!.status, ActiveActivityStatus.paused);
      expect(adapter.listenCount, 0);
    });

    test('recoverActiveSession restarts monitoring when auto-paused', () async {
      final startedAt = DateTime.utc(2026, 6, 3, 9);
      store.session = ActiveActivitySession(
        localSessionId: 'session_1',
        activityType: ActivityType.run,
        status: ActiveActivityStatus.paused,
        startedAt: startedAt,
        autoPauseEnabled: true,
        pausedAutomatically: true,
      );
      await store.appendPoints([
        RecordedActivityPoint(
          timestamp: startedAt,
          latitude: 41.1,
          longitude: -8.6,
          segmentIndex: 0,
          speedMetersPerSecond: 0,
          horizontalAccuracyMeters: 5,
        ),
      ]);

      await recorder.recoverActiveSession();

      expect(adapter.listenCount, 1);
      for (var second = 1; second <= 3; second += 1) {
        adapter.addPosition(
          recordingPosition(
            latitude: 41.1 + second / 100,
            longitude: -8.6,
            timestamp: startedAt.add(Duration(seconds: second)),
            speed: 2,
          ),
        );
        await pumpEventQueue();
      }
      expect(store.session?.status, ActiveActivityStatus.recording);
      expect(store.points.last.segmentIndex, 1);
    });

    test('drain records sanitized point batch metadata', () async {
      await recorder.start(request());
      adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
      await pumpEventQueue();

      final drained = await recorder.drain(sinceOffset: 0);

      expect(drained, hasLength(1));
      final details = diagnostics.detailsFor(
        DiagnosticsEvents.activityPointBatchDrained,
      );
      expect(details, {'pointCount': 1, 'sinceOffset': 0});
    });

    test('tracking stall diagnostics contain no coordinates', () async {
      await recorder.start(request());
      adapter.addPosition(
        recordingPosition(latitude: 41.1, longitude: -8.6, timestamp: now),
      );
      await pumpEventQueue();
      now = now.add(const Duration(minutes: 2));
      adapter.addPosition(
        recordingPosition(latitude: 41.2, longitude: -8.7, timestamp: now),
      );
      await pumpEventQueue();

      final details = diagnostics.detailsFor(
        DiagnosticsEvents.activityTrackingStall,
      );
      expect(details?['reason'], 'timeGap');
      expect(details?['gapSeconds'], 120);
      expect(details?.containsKey('latitude'), isFalse);
      expect(details?.containsKey('longitude'), isFalse);
      expect(details?.containsKey('lat'), isFalse);
      expect(details?.containsKey('lon'), isFalse);
    });

    test('emits a failure when the stream errors', () async {
      final failures = <ActivityRecorderFailureReason>[];
      final subscription = recorder.events
          .where((event) => event.type == ActivityRecorderEventType.failed)
          .listen((event) => failures.add(event.failureReason!));
      addTearDown(subscription.cancel);

      await recorder.start(request());
      adapter.addError(StateError('boom'));
      await pumpEventQueue();

      expect(
        failures,
        contains(ActivityRecorderFailureReason.locationStreamFailed),
      );
    });
  });
}

class _FakeDiagnosticsRecorder implements DiagnosticsRecorder {
  final List<String> events = [];
  final List<Map<String, Object?>> breadcrumbDetails = [];

  Map<String, Object?>? detailsFor(String event) {
    for (var index = events.length - 1; index >= 0; index -= 1) {
      if (events[index] == event) {
        return breadcrumbDetails[index];
      }
    }
    return null;
  }

  @override
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  }) {
    events.add(event);
    breadcrumbDetails.add(details);
  }

  @override
  void recordErrorSync(
    Object error,
    StackTrace stackTrace, {
    String source = DiagnosticsSources.uncaught,
  }) {}
}
