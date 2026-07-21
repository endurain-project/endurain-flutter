import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'dart:async';

import 'package:async/async.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/activity_recording_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

import '../../../helpers/recording_location_platform_adapter.dart';

void main() {
  group('ActivityRecordingService', () {
    test('starts recording and emits state', () async {
      final startedAt = DateTime.utc(2026, 5, 30, 10);
      final recorder = _ControllableRecorder();
      final diagnostics = _FakeDiagnosticsRecorder();
      final service = _buildService(
        recorder: recorder,
        diagnostics: diagnostics,
        now: () => startedAt,
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(service.state.status, ActivityRecordingStatus.recording);
      expect(service.state.activityType, ActivityType.run);
      expect(service.state.startedAt, startedAt);
      expect(service.state.points, isEmpty);
      expect(service.state.segments, hasLength(1));
      expect(service.state.segments.single.points, isEmpty);
      expect(recorder.startCount, 1);
      expect(
        diagnostics.events,
        containsAllInOrder([
          DiagnosticsEvents.activityStartRequested,
          DiagnosticsEvents.activityStarted,
        ]),
      );
    });

    test('forwards background config to the recorder', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final recorder = _ControllableRecorder();
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      const config = BackgroundLocationConfig(
        notificationTitle: 'Recording activity',
        notificationText: 'Tracking your location.',
      );
      await service.start(
        activityType: ActivityType.run,
        backgroundConfig: config,
      );

      expect(recorder.lastStartRequest?.backgroundConfig, same(config));
    });

    test('uses configured background tracking for recording starts', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final recorder = _ControllableRecorder();
      final service = _buildService(
        recorder: recorder,
        locationService: _location(LocationPermission.always),
      );
      service.configureBackgroundTracking(
        const BackgroundLocationConfig(
          notificationTitle: 'Recording activity',
          notificationText: 'Tracking your location.',
        ),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(service.state.status, ActivityRecordingStatus.recording);
      expect(recorder.lastStartRequest?.backgroundConfig, isNotNull);
    });

    test('requires always permission for background tracking on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final recorder = _ControllableRecorder();
      final service = _buildService(
        recorder: recorder,
        locationService: _location(LocationPermission.whileInUse),
      );
      addTearDown(service.dispose);

      await service.start(
        activityType: ActivityType.run,
        backgroundConfig: const BackgroundLocationConfig(
          notificationTitle: 'Recording activity',
          notificationText: 'Tracking your location.',
        ),
      );

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastError,
        ActivityRecordingError.backgroundPermissionRequired,
      );
      expect(recorder.startCount, 0);
    });

    test('does not start when location services are disabled', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(
        recorder: recorder,
        locationService: LocationService(
          platformAdapter: RecordingLocationPlatformAdapter(
            serviceEnabled: false,
          ),
        ),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastError,
        ActivityRecordingError.locationServiceDisabled,
      );
      expect(recorder.startCount, 0);
    });

    test('does not start when permission is denied', () async {
      final recorder = _ControllableRecorder();
      final adapter = RecordingLocationPlatformAdapter(
        permission: LocationPermission.denied,
        requestedPermission: LocationPermission.denied,
      );
      final service = _buildService(
        recorder: recorder,
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastError,
        ActivityRecordingError.locationPermissionDenied,
      );
      expect(adapter.requestPermissionCalled, isTrue);
      expect(recorder.startCount, 0);
    });

    test('does not start when permission is denied forever', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(
        recorder: recorder,
        locationService: _location(LocationPermission.deniedForever),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastError,
        ActivityRecordingError.locationPermissionDeniedForever,
      );
      expect(recorder.startCount, 0);
    });

    test('records recorder point batches as track points', () async {
      final recorder = _ControllableRecorder();
      final diagnostics = _FakeDiagnosticsRecorder();
      final service = _buildService(
        recorder: recorder,
        diagnostics: diagnostics,
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      recorder.emitPoints([_point(latitude: 41.1, longitude: -8.6)]);
      await pumpEventQueue();

      expect(service.state.points, hasLength(1));
      expect(service.state.points.single.latitude, 41.1);
      expect(service.state.points.single.longitude, -8.6);
      expect(
        diagnostics.events,
        contains(DiagnosticsEvents.activityPointMilestone),
      );
    });

    test('emits a single state update for a multi-point batch', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      final states = <ActivityRecordingState>[];
      final subscription = service.stateStream.listen(states.add);
      addTearDown(subscription.cancel);

      recorder.emitPoints([
        for (var i = 0; i < 10; i += 1)
          _point(latitude: 41 + i * 0.01, longitude: -8),
      ]);
      await pumpEventQueue();

      // The whole 10-point batch must produce exactly one emission, not one
      // per point.
      expect(states, hasLength(1));
      expect(states.single.points, hasLength(10));
      expect(service.state.points, hasLength(10));
      expect(service.state.segments, hasLength(1));
    });

    test('updates elapsed duration while recording without GPS points', () {
      fakeAsync((async) {
        var now = DateTime.utc(2026, 5, 30, 10);
        final service = _buildService(
          recorder: _ControllableRecorder(),
          now: () => now,
        );

        unawaited(service.start(activityType: ActivityType.run));
        async.flushMicrotasks();

        expect(service.state.elapsedDurationSeconds, 0);

        now = now.add(const Duration(seconds: 1));
        async.elapse(const Duration(seconds: 1));

        expect(service.state.status, ActivityRecordingStatus.recording);
        expect(service.state.points, isEmpty);
        expect(service.state.elapsedDurationSeconds, 1);

        service.dispose();
      });
    });

    test('does not count paused time in elapsed duration', () {
      fakeAsync((async) {
        var now = DateTime.utc(2026, 5, 30, 10);
        final service = _buildService(
          recorder: _ControllableRecorder(),
          now: () => now,
        );

        unawaited(service.start(activityType: ActivityType.ride));
        async.flushMicrotasks();
        now = now.add(const Duration(seconds: 3));
        unawaited(service.pause());
        async.flushMicrotasks();

        expect(service.state.status, ActivityRecordingStatus.paused);
        expect(service.state.elapsedDurationSeconds, 3);

        now = now.add(const Duration(seconds: 10));
        async.elapse(const Duration(seconds: 10));

        expect(service.state.elapsedDurationSeconds, 3);

        unawaited(service.resume());
        async.flushMicrotasks();
        now = now.add(const Duration(seconds: 2));
        async.elapse(const Duration(seconds: 2));

        expect(service.state.status, ActivityRecordingStatus.recording);
        expect(service.state.elapsedDurationSeconds, 5);

        service.dispose();
      });
    });

    test('pause and resume update state and delegate to recorder', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.ride);
      await service.pause();

      expect(service.state.status, ActivityRecordingStatus.paused);
      expect(recorder.pauseCount, 1);

      await service.resume();

      expect(service.state.status, ActivityRecordingStatus.recording);
      expect(recorder.resumeCount, 1);
    });

    test('pause and resume split track points into segments', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      recorder.emitPoints([_point(latitude: 41.1, longitude: -8.6)]);
      await pumpEventQueue();
      await service.pause();
      await service.resume();
      recorder.emitPoints([
        _point(latitude: 41.2, longitude: -8.7, segmentIndex: 1),
      ]);
      await pumpEventQueue();

      expect(service.state.points, hasLength(2));
      expect(service.state.segments, hasLength(2));
      expect(service.state.segments.first.points.single.latitude, 41.1);
      expect(service.state.segments.last.points.single.latitude, 41.2);
    });

    test('stop finalizes durable points and completes', () async {
      final recorder = _ControllableRecorder();
      var now = DateTime.utc(2026, 5, 30, 10);
      final service = _buildService(recorder: recorder, now: () => now);
      addTearDown(service.dispose);
      final states = <ActivityRecordingState>[];
      final subscription = service.stateStream.listen(states.add);
      addTearDown(subscription.cancel);

      await service.start(activityType: ActivityType.walk);
      recorder.emitPoints([_point(latitude: 41.1, longitude: -8.6)]);
      await pumpEventQueue();
      now = DateTime.utc(2026, 5, 30, 11);
      await service.stop();
      await pumpEventQueue();

      expect(
        states.map((state) => state.status),
        containsAllInOrder([
          ActivityRecordingStatus.recording,
          ActivityRecordingStatus.stopping,
          ActivityRecordingStatus.completed,
        ]),
      );
      expect(service.state.status, ActivityRecordingStatus.completed);
      expect(service.state.endedAt, DateTime.utc(2026, 5, 30, 11));
      expect(recorder.stopCount, 1);
    });

    test('empty stop fails safely without completing', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      await service.stop();

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(service.state.lastError, ActivityRecordingError.emptyRecording);
      expect(recorder.stopCount, 1);
      expect(recorder.discardCount, 1);
    });

    test('stop drains points persisted while stopping', () async {
      final recorder = _ControllableRecorder(
        pointsPersistedOnStop: [_point(latitude: 41.1, longitude: -8.6)],
      );
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.walk);
      await service.stop();

      expect(service.state.status, ActivityRecordingStatus.completed);
      expect(service.state.points, hasLength(1));
      expect(service.state.points.single.latitude, 41.1);
      expect(recorder.stopCount, 1);
    });

    test('duplicate start keeps current recording', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      final startedAt = service.state.startedAt;
      await service.start(activityType: ActivityType.ride);

      expect(service.state.status, ActivityRecordingStatus.recording);
      expect(service.state.activityType, ActivityType.run);
      expect(service.state.startedAt, startedAt);
      expect(recorder.startCount, 1);
    });

    test(
      'invalid pause moves to failed state without raw error details',
      () async {
        final service = _buildService(recorder: _ControllableRecorder());
        addTearDown(service.dispose);

        await service.pause();

        expect(service.state.status, ActivityRecordingStatus.failed);
        expect(
          service.state.lastError,
          ActivityRecordingError.invalidTransition,
        );
      },
    );

    test('invalid resume from idle moves to failed state', () async {
      final service = _buildService(recorder: _ControllableRecorder());
      addTearDown(service.dispose);

      await service.resume();

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(service.state.lastError, ActivityRecordingError.invalidTransition);
    });

    test('pausing twice is idempotent', () async {
      final service = _buildService(recorder: _ControllableRecorder());
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      await service.pause();
      await service.pause();

      expect(service.state.status, ActivityRecordingStatus.paused);
      expect(service.state.lastError, isNull);
    });

    test('resuming while already recording is a no-op', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      await service.resume();

      expect(service.state.status, ActivityRecordingStatus.recording);
      expect(service.state.lastError, isNull);
      expect(recorder.resumeCount, 0);
    });

    test('stopping while idle leaves the state untouched', () async {
      final service = _buildService(recorder: _ControllableRecorder());
      addTearDown(service.dispose);

      await service.stop();

      expect(service.state.status, ActivityRecordingStatus.idle);
      expect(service.state.lastError, isNull);
    });

    test('operations after dispose throw a guarded state error', () async {
      final service = _buildService(recorder: _ControllableRecorder());
      service.dispose();

      expect(
        () => service.start(activityType: ActivityType.run),
        throwsStateError,
      );
    });

    test('discard is idempotent and clears state', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.hike);
      await service.discard();
      await service.discard();

      expect(service.state.status, ActivityRecordingStatus.idle);
      expect(service.state.activityType, isNull);
      expect(service.state.points, isEmpty);
      expect(recorder.discardCount, greaterThanOrEqualTo(1));
    });

    test(
      'recorder errors fail recording without erasing durable data',
      () async {
        final recorder = _ControllableRecorder();
        final diagnostics = _FakeDiagnosticsRecorder();
        final service = _buildService(
          recorder: recorder,
          diagnostics: diagnostics,
        );
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        recorder.emitError(StateError('recorder failed'));
        await pumpEventQueue();

        expect(service.state.status, ActivityRecordingStatus.failed);
        expect(
          service.state.lastError,
          ActivityRecordingError.locationStreamFailed,
        );
        expect(recorder.discardCount, 0);
        expect(
          diagnostics.errorSources,
          contains(DiagnosticsSources.activityRecorder),
        );
      },
    );

    test('recorder failure events map to typed error keys', () async {
      final recorder = _ControllableRecorder();
      final service = _buildService(recorder: recorder);
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      recorder.emitFailure(ActivityRecorderFailureReason.permissionLost);
      await pumpEventQueue();

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastError,
        ActivityRecordingError.locationPermissionDenied,
      );
    });

    test(
      'point milestone records counts without per-point gap details',
      () async {
        final recorder = _ControllableRecorder();
        final diagnostics = _FakeDiagnosticsRecorder();
        final service = _buildService(
          recorder: recorder,
          diagnostics: diagnostics,
        );
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        recorder.emitPoints([
          for (var i = 0; i < 26; i += 1)
            _point(latitude: 41 + i * 0.01, longitude: -8),
        ]);
        await pumpEventQueue();

        final details = diagnostics.detailsFor(
          DiagnosticsEvents.activityPointMilestone,
        );
        expect(details?['pointCount'], 26);
        expect(details?.containsKey('secondsSinceLastPoint'), isFalse);
      },
    );

    group('heart rate stamping', () {
      final pointTime = DateTime.utc(2026, 5, 30, 10, 0, 30);

      test('stamps the nearest live reading onto recorded points', () async {
        final recorder = _ControllableRecorder();
        final heartRate =
            StreamController<({DateTime timestamp, int bpm})>.broadcast();
        addTearDown(heartRate.close);
        final service = _buildService(
          recorder: recorder,
          heartRateReadings: heartRate.stream,
        );
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        heartRate.add((timestamp: pointTime, bpm: 142));
        await pumpEventQueue();
        recorder.emitPoints([
          _point(latitude: 41.1, longitude: -8.6, timestamp: pointTime),
        ]);
        await pumpEventQueue();

        expect(service.state.points.single.heartRateBpm, 142);
      });

      test('exposes the live bpm immediately, before any point', () async {
        final recorder = _ControllableRecorder();
        final heartRate =
            StreamController<({DateTime timestamp, int bpm})>.broadcast();
        addTearDown(heartRate.close);
        final service = _buildService(
          recorder: recorder,
          heartRateReadings: heartRate.stream,
        );
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        expect(service.state.currentHeartRateBpm, isNull);

        heartRate.add((timestamp: pointTime, bpm: 142));
        await pumpEventQueue();

        // No GPS point recorded yet, but the live bpm is already surfaced.
        expect(service.state.points, isEmpty);
        expect(service.state.currentHeartRateBpm, 142);

        heartRate.add((timestamp: pointTime, bpm: 150));
        await pumpEventQueue();
        expect(service.state.currentHeartRateBpm, 150);
      });

      test(
        'leaves heart rate null when no reading is within the window',
        () async {
          final recorder = _ControllableRecorder();
          final heartRate =
              StreamController<({DateTime timestamp, int bpm})>.broadcast();
          addTearDown(heartRate.close);
          final service = _buildService(
            recorder: recorder,
            heartRateReadings: heartRate.stream,
          );
          addTearDown(service.dispose);

          await service.start(activityType: ActivityType.run);
          // 30s before the point is outside the 10s freshness window.
          heartRate.add((
            timestamp: pointTime.subtract(const Duration(seconds: 30)),
            bpm: 142,
          ));
          await pumpEventQueue();
          recorder.emitPoints([
            _point(latitude: 41.1, longitude: -8.6, timestamp: pointTime),
          ]);
          await pumpEventQueue();

          expect(service.state.points.single.heartRateBpm, isNull);
        },
      );

      test('keeps heart rate through the finalized stopped state', () async {
        final recorder = _ControllableRecorder();
        final heartRate =
            StreamController<({DateTime timestamp, int bpm})>.broadcast();
        addTearDown(heartRate.close);
        final service = _buildService(
          recorder: recorder,
          heartRateReadings: heartRate.stream,
        );
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        heartRate.add((timestamp: pointTime, bpm: 150));
        await pumpEventQueue();
        recorder.emitPoints([
          _point(latitude: 41.1, longitude: -8.6, timestamp: pointTime),
        ]);
        await pumpEventQueue();

        await service.stop();
        await pumpEventQueue();

        expect(service.state.status, ActivityRecordingStatus.completed);
        expect(service.state.points.single.heartRateBpm, 150);
      });

      test('leaves heart rate null without a heart-rate source', () async {
        final recorder = _ControllableRecorder();
        final service = _buildService(recorder: recorder);
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        recorder.emitPoints([
          _point(latitude: 41.1, longitude: -8.6, timestamp: pointTime),
        ]);
        await pumpEventQueue();

        expect(service.state.points.single.heartRateBpm, isNull);
      });

      test(
        'passes the prepared heart-rate device id to the recorder',
        () async {
          final recorder = _ControllableRecorder();
          final service = _buildService(
            recorder: recorder,
            prepareHeartRateSource: () async => 'AA:BB:CC',
          );
          addTearDown(service.dispose);

          await service.start(activityType: ActivityType.run);

          expect(recorder.lastStartRequest?.heartRateDeviceId, 'AA:BB:CC');
        },
      );

      test(
        'passes the prepared power and cadence device ids to the recorder',
        () async {
          final recorder = _ControllableRecorder();
          final service = _buildService(
            recorder: recorder,
            preparePowerSource: () async => 'PW:11:22',
            prepareCadenceSource: () async => 'CA:33:44',
          );
          addTearDown(service.dispose);

          await service.start(activityType: ActivityType.run);

          expect(recorder.lastStartRequest?.powerDeviceId, 'PW:11:22');
          expect(recorder.lastStartRequest?.cadenceDeviceId, 'CA:33:44');
        },
      );
    });

    group('power and cadence stamping', () {
      final pointTime = DateTime.utc(2026, 5, 30, 10, 0, 30);

      test('stamps the nearest live power and cadence onto points', () async {
        final recorder = _ControllableRecorder();
        final power =
            StreamController<({DateTime timestamp, int watts})>.broadcast();
        final cadence =
            StreamController<({DateTime timestamp, int rpm})>.broadcast();
        addTearDown(power.close);
        addTearDown(cadence.close);
        final service = _buildService(
          recorder: recorder,
          powerReadings: power.stream,
          cadenceReadings: cadence.stream,
        );
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        power.add((timestamp: pointTime, watts: 240));
        cadence.add((timestamp: pointTime, rpm: 88));
        await pumpEventQueue();
        recorder.emitPoints([
          _point(latitude: 41.1, longitude: -8.6, timestamp: pointTime),
        ]);
        await pumpEventQueue();

        expect(service.state.points.single.powerWatts, 240);
        expect(service.state.points.single.cadenceRpm, 88);
      });

      test('exposes live power and cadence before any point', () async {
        final recorder = _ControllableRecorder();
        final power =
            StreamController<({DateTime timestamp, int watts})>.broadcast();
        final cadence =
            StreamController<({DateTime timestamp, int rpm})>.broadcast();
        addTearDown(power.close);
        addTearDown(cadence.close);
        final service = _buildService(
          recorder: recorder,
          powerReadings: power.stream,
          cadenceReadings: cadence.stream,
        );
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        expect(service.state.currentPowerWatts, isNull);
        expect(service.state.currentCadenceRpm, isNull);

        power.add((timestamp: pointTime, watts: 240));
        cadence.add((timestamp: pointTime, rpm: 88));
        await pumpEventQueue();

        expect(service.state.points, isEmpty);
        expect(service.state.currentPowerWatts, 240);
        expect(service.state.currentCadenceRpm, 88);
      });

      test('leaves power and cadence null outside the window', () async {
        final recorder = _ControllableRecorder();
        final power =
            StreamController<({DateTime timestamp, int watts})>.broadcast();
        final cadence =
            StreamController<({DateTime timestamp, int rpm})>.broadcast();
        addTearDown(power.close);
        addTearDown(cadence.close);
        final service = _buildService(
          recorder: recorder,
          powerReadings: power.stream,
          cadenceReadings: cadence.stream,
        );
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        // 30s before the point is outside the 10s freshness window.
        power.add((
          timestamp: pointTime.subtract(const Duration(seconds: 30)),
          watts: 240,
        ));
        cadence.add((
          timestamp: pointTime.subtract(const Duration(seconds: 30)),
          rpm: 88,
        ));
        await pumpEventQueue();
        recorder.emitPoints([
          _point(latitude: 41.1, longitude: -8.6, timestamp: pointTime),
        ]);
        await pumpEventQueue();

        expect(service.state.points.single.powerWatts, isNull);
        expect(service.state.points.single.cadenceRpm, isNull);
      });

      test('leaves power and cadence null without a source', () async {
        final recorder = _ControllableRecorder();
        final service = _buildService(recorder: recorder);
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        recorder.emitPoints([
          _point(latitude: 41.1, longitude: -8.6, timestamp: pointTime),
        ]);
        await pumpEventQueue();

        expect(service.state.points.single.powerWatts, isNull);
        expect(service.state.points.single.cadenceRpm, isNull);
      });
    });
  });
}

ActivityRecordingService _buildService({
  required ActivityLocationRecorder recorder,
  LocationService? locationService,
  DiagnosticsRecorder? diagnostics,
  DateTime Function()? now,
  Stream<({DateTime timestamp, int bpm})>? heartRateReadings,
  Stream<({DateTime timestamp, int watts})>? powerReadings,
  Stream<({DateTime timestamp, int rpm})>? cadenceReadings,
  Duration sensorFreshness = const Duration(seconds: 10),
  Future<String?> Function()? prepareHeartRateSource,
  Future<String?> Function()? preparePowerSource,
  Future<String?> Function()? prepareCadenceSource,
}) {
  // Adapt the per-kind test streams/preparers to the unified sensor pipeline so
  // the individual test bodies keep expressing intent in typed terms.
  final sensorStreams = <Stream<RecordedSensorSample>>[
    if (heartRateReadings != null)
      heartRateReadings.map(
        (reading) => RecordedSensorSample(
          kind: RecordedSensorKind.heartRate,
          timestamp: reading.timestamp,
          value: reading.bpm,
        ),
      ),
    if (powerReadings != null)
      powerReadings.map(
        (reading) => RecordedSensorSample(
          kind: RecordedSensorKind.power,
          timestamp: reading.timestamp,
          value: reading.watts,
        ),
      ),
    if (cadenceReadings != null)
      cadenceReadings.map(
        (reading) => RecordedSensorSample(
          kind: RecordedSensorKind.cadence,
          timestamp: reading.timestamp,
          value: reading.rpm,
        ),
      ),
  ];
  return ActivityRecordingService(
    recorder: recorder,
    locationService:
        locationService ??
        LocationService(platformAdapter: RecordingLocationPlatformAdapter()),
    diagnostics: diagnostics,
    now: now,
    sensorReadings: sensorStreams.isEmpty
        ? null
        : StreamGroup.merge(sensorStreams),
    prepareSensorSources: <RecordedSensorKind, Future<String?> Function()>{
      RecordedSensorKind.heartRate: ?prepareHeartRateSource,
      RecordedSensorKind.power: ?preparePowerSource,
      RecordedSensorKind.cadence: ?prepareCadenceSource,
    },
    sensorFreshness: sensorFreshness,
  );
}

LocationService _location(LocationPermission permission) {
  return LocationService(
    platformAdapter: RecordingLocationPlatformAdapter(permission: permission),
  );
}

RecordedActivityPoint _point({
  required double latitude,
  required double longitude,
  int segmentIndex = 0,
  DateTime? timestamp,
}) {
  return RecordedActivityPoint(
    timestamp: timestamp ?? DateTime.utc(2026, 5, 30, 10),
    latitude: latitude,
    longitude: longitude,
    segmentIndex: segmentIndex,
  );
}

/// A controllable [ActivityLocationRecorder] fake for service-level tests.
///
/// Lets tests drive recorder events (point batches, failures, stream errors)
/// and durable drains independently of any platform location stream.
class _ControllableRecorder implements ActivityLocationRecorder {
  _ControllableRecorder({this._pointsPersistedOnStop = const []});

  final StreamController<ActivityRecorderEvent> _controller =
      StreamController<ActivityRecorderEvent>.broadcast();
  final List<RecordedActivityPoint> _drained = [];
  final List<RecordedActivityPoint> _pointsPersistedOnStop;
  ActivityRecorderStartRequest? lastStartRequest;
  int startCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;
  int discardCount = 0;

  @override
  Stream<ActivityRecorderEvent> get events => _controller.stream;

  @override
  Future<void> start(ActivityRecorderStartRequest request) async {
    startCount += 1;
    lastStartRequest = request;
  }

  @override
  Future<void> pause() async {
    pauseCount += 1;
  }

  @override
  Future<void> resume() async {
    resumeCount += 1;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    _drained.addAll(_pointsPersistedOnStop);
  }

  @override
  Future<void> discard() async {
    discardCount += 1;
    _drained.clear();
  }

  @override
  Future<List<RecordedActivityPoint>> drain({int sinceOffset = 0}) async {
    return _drained.sublist(sinceOffset.clamp(0, _drained.length));
  }

  @override
  Future<ActiveActivitySession?> recoverActiveSession() async {
    return null;
  }

  @override
  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void emitPoints(List<RecordedActivityPoint> points) {
    _drained.addAll(points);
    _controller.add(ActivityRecorderEvent.pointBatchAvailable(points));
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  void emitFailure(ActivityRecorderFailureReason reason) {
    _controller.add(ActivityRecorderEvent.failed(reason));
  }
}

class _FakeDiagnosticsRecorder implements DiagnosticsRecorder {
  final List<String> events = [];
  final List<Map<String, Object?>> breadcrumbDetails = [];
  final List<String> errorSources = [];

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
  }) {
    errorSources.add(source);
  }
}
