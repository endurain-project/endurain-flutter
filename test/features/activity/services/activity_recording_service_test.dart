import 'dart:async';

import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
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
      final adapter = RecordingLocationPlatformAdapter();
      final diagnostics = _FakeDiagnosticsRecorder();
      final service = ActivityRecordingService(
        now: () => startedAt,
        diagnostics: diagnostics,
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(service.state.status, ActivityRecordingStatus.recording);
      expect(service.state.activityType, ActivityType.run);
      expect(service.state.startedAt, startedAt);
      expect(service.state.points, isEmpty);
      expect(service.state.segments, hasLength(1));
      expect(service.state.segments.single.points, isEmpty);
      expect(adapter.listenCount, 1);
      expect(
        diagnostics.events,
        containsAllInOrder([
          DiagnosticsEvents.activityStartRequested,
          DiagnosticsEvents.activityStarted,
        ]),
      );
    });

    test('uses responsive location updates while recording', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(
        adapter.lastPositionStreamSettings?.distanceFilter,
        LocationDistanceFilters.recordingMeters,
      );
    });

    test('forwards background config to the location stream', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final adapter = RecordingLocationPlatformAdapter();
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(
        activityType: ActivityType.run,
        backgroundConfig: const BackgroundLocationConfig(
          notificationTitle: 'Recording activity',
          notificationText: 'Tracking your location.',
        ),
      );

      expect(adapter.lastPositionStreamSettings, isA<AndroidSettings>());
    });

    test('uses configured background tracking for recording starts', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final adapter = RecordingLocationPlatformAdapter(
        permission: LocationPermission.always,
      );
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      service.configureBackgroundTracking(
        const BackgroundLocationConfig(
          notificationTitle: 'Recording activity',
          notificationText: 'Tracking your location.',
        ),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(adapter.lastPositionStreamSettings, isA<AppleSettings>());
      final settings = adapter.lastPositionStreamSettings! as AppleSettings;
      expect(settings.allowBackgroundLocationUpdates, isTrue);
      expect(settings.pauseLocationUpdatesAutomatically, isFalse);
    });

    test('requires always permission for background tracking on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final adapter = RecordingLocationPlatformAdapter(
        permission: LocationPermission.whileInUse,
      );
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
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
        service.state.lastErrorKey,
        ActivityRecordingErrorKeys.backgroundPermissionRequired,
      );
      expect(adapter.listenCount, 0);
    });
    test('does not start when location services are disabled', () async {
      final adapter = RecordingLocationPlatformAdapter(serviceEnabled: false);
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastErrorKey,
        ActivityRecordingErrorKeys.locationServiceDisabled,
      );
      expect(adapter.listenCount, 0);
    });

    test('does not start when permission is denied', () async {
      final adapter = RecordingLocationPlatformAdapter(
        permission: LocationPermission.denied,
        requestedPermission: LocationPermission.denied,
      );
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastErrorKey,
        ActivityRecordingErrorKeys.locationPermissionDenied,
      );
      expect(adapter.requestPermissionCalled, isTrue);
      expect(adapter.listenCount, 0);
    });

    test('does not start when permission is denied forever', () async {
      final adapter = RecordingLocationPlatformAdapter(
        permission: LocationPermission.deniedForever,
      );
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastErrorKey,
        ActivityRecordingErrorKeys.locationPermissionDeniedForever,
      );
      expect(adapter.listenCount, 0);
    });

    test('records position updates as track points', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final diagnostics = _FakeDiagnosticsRecorder();
      final service = ActivityRecordingService(
        diagnostics: diagnostics,
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
      await pumpEventQueue();

      expect(service.state.points, hasLength(1));
      expect(service.state.points.single.latitude, 41.1);
      expect(service.state.points.single.longitude, -8.6);
      expect(
        diagnostics.events,
        contains(DiagnosticsEvents.activityPointMilestone),
      );
    });

    test('updates elapsed duration while recording without GPS points', () {
      fakeAsync((async) {
        var now = DateTime.utc(2026, 5, 30, 10);
        final adapter = RecordingLocationPlatformAdapter();
        final service = ActivityRecordingService(
          now: () => now,
          locationService: LocationService(platformAdapter: adapter),
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
        final adapter = RecordingLocationPlatformAdapter();
        final service = ActivityRecordingService(
          now: () => now,
          locationService: LocationService(platformAdapter: adapter),
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

    test('pause and resume update state', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.ride);
      await service.pause();

      expect(service.state.status, ActivityRecordingStatus.paused);
      expect(adapter.cancelCount, 1);

      await service.resume();

      expect(service.state.status, ActivityRecordingStatus.recording);
      expect(adapter.listenCount, 2);
    });

    test('pause and resume split track points into segments', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
      await pumpEventQueue();
      await service.pause();
      await service.resume();
      adapter.addPosition(recordingPosition(latitude: 41.2, longitude: -8.7));
      await pumpEventQueue();

      expect(service.state.points, hasLength(2));
      expect(service.state.segments, hasLength(2));
      expect(service.state.segments.first.points.single.latitude, 41.1);
      expect(service.state.segments.last.points.single.latitude, 41.2);
    });

    test('stop emits stopping then completed', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final completedAt = DateTime.utc(2026, 5, 30, 11);
      var calls = 0;
      final service = ActivityRecordingService(
        now: () => calls++ == 0 ? DateTime.utc(2026, 5, 30, 10) : completedAt,
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);
      final states = <ActivityRecordingState>[];
      final subscription = service.stateStream.listen(states.add);
      addTearDown(subscription.cancel);

      await service.start(activityType: ActivityType.walk);
      adapter.addPosition(recordingPosition(latitude: 41.1, longitude: -8.6));
      await pumpEventQueue();
      await service.stop();
      await pumpEventQueue();

      expect(states.map((state) => state.status), [
        ActivityRecordingStatus.recording,
        ActivityRecordingStatus.recording,
        ActivityRecordingStatus.stopping,
        ActivityRecordingStatus.completed,
      ]);
      expect(service.state.endedAt, completedAt);
      expect(adapter.cancelCount, 1);
    });

    test('empty stop fails safely without completing', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      await service.stop();

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastErrorKey,
        ActivityRecordingErrorKeys.emptyRecording,
      );
    });

    test('duplicate start keeps current recording', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      final startedAt = service.state.startedAt;
      await service.start(activityType: ActivityType.ride);

      expect(service.state.status, ActivityRecordingStatus.recording);
      expect(service.state.activityType, ActivityType.run);
      expect(service.state.startedAt, startedAt);
      expect(adapter.listenCount, 1);
    });

    test(
      'invalid pause moves to failed state without raw error details',
      () async {
        final service = ActivityRecordingService();
        addTearDown(service.dispose);

        await service.pause();

        expect(service.state.status, ActivityRecordingStatus.failed);
        expect(
          service.state.lastErrorKey,
          ActivityRecordingErrorKeys.invalidTransition,
        );
      },
    );

    test('invalid resume from idle moves to failed state', () async {
      final service = ActivityRecordingService();
      addTearDown(service.dispose);

      await service.resume();

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastErrorKey,
        ActivityRecordingErrorKeys.invalidTransition,
      );
    });

    test('pausing twice is idempotent', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      await service.pause();
      await service.pause();

      expect(service.state.status, ActivityRecordingStatus.paused);
      expect(service.state.lastErrorKey, isNull);
    });

    test('resuming while already recording is a no-op', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      await service.resume();

      expect(service.state.status, ActivityRecordingStatus.recording);
      expect(service.state.lastErrorKey, isNull);
      expect(adapter.listenCount, 1);
    });

    test('stopping while idle leaves the state untouched', () async {
      final service = ActivityRecordingService();
      addTearDown(service.dispose);

      await service.stop();

      expect(service.state.status, ActivityRecordingStatus.idle);
      expect(service.state.lastErrorKey, isNull);
    });

    test('operations after dispose throw a guarded state error', () async {
      final service = ActivityRecordingService();
      service.dispose();

      expect(
        () => service.start(activityType: ActivityType.run),
        throwsStateError,
      );
    });

    test('discard is idempotent and clears state', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final service = ActivityRecordingService(
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.hike);
      await service.discard();
      await service.discard();

      expect(service.state.status, ActivityRecordingStatus.idle);
      expect(service.state.activityType, isNull);
      expect(service.state.points, isEmpty);
      expect(adapter.cancelCount, 1);
    });

    test('stream errors fail recording and cancel subscription', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final diagnostics = _FakeDiagnosticsRecorder();
      final service = ActivityRecordingService(
        diagnostics: diagnostics,
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      adapter.addError(StateError('stream failed'));
      await pumpEventQueue();

      expect(service.state.status, ActivityRecordingStatus.failed);
      expect(
        service.state.lastErrorKey,
        ActivityRecordingErrorKeys.locationStreamFailed,
      );
      expect(adapter.cancelCount, 1);
      expect(
        diagnostics.errorSources,
        contains(DiagnosticsSources.activityLocationStream),
      );
    });

    test('records a breadcrumb when the location stream closes', () async {
      final adapter = RecordingLocationPlatformAdapter();
      final diagnostics = _FakeDiagnosticsRecorder();
      final service = ActivityRecordingService(
        diagnostics: diagnostics,
        locationService: LocationService(platformAdapter: adapter),
      );
      addTearDown(service.dispose);

      await service.start(activityType: ActivityType.run);
      await adapter.closeStream();
      await pumpEventQueue();

      expect(
        diagnostics.events,
        contains(DiagnosticsEvents.activityLocationStreamDone),
      );
      final details = diagnostics.detailsFor(
        DiagnosticsEvents.activityLocationStreamDone,
      );
      expect(details?['status'], ActivityRecordingStatus.recording.name);
      expect(details?['pointCount'], 0);
    });

    test(
      'point milestone records counts without per-point gap details',
      () async {
        var now = DateTime.utc(2026, 5, 30, 10);
        final adapter = RecordingLocationPlatformAdapter();
        final diagnostics = _FakeDiagnosticsRecorder();
        final service = ActivityRecordingService(
          now: () => now,
          diagnostics: diagnostics,
          locationService: LocationService(platformAdapter: adapter),
        );
        addTearDown(service.dispose);

        await service.start(activityType: ActivityType.run);
        for (var i = 0; i < 26; i += 1) {
          now = now.add(const Duration(seconds: 2));
          adapter.addPosition(
            recordingPosition(latitude: 41 + i * 0.01, longitude: -8),
          );
          await pumpEventQueue();
        }

        final details = diagnostics.detailsFor(
          DiagnosticsEvents.activityPointMilestone,
        );
        expect(details?['pointCount'], 26);
        expect(details?.containsKey('secondsSinceLastPoint'), isFalse);
      },
    );
  });
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
