import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityRecordingState', () {
    test('copyWith updates state and keeps existing values', () {
      final startedAt = DateTime.utc(2026, 5, 30, 10);
      final state = ActivityRecordingState(
        status: ActivityRecordingStatus.recording,
        activityType: ActivityType.run,
        startedAt: startedAt,
      );

      final updated = state.copyWith(status: ActivityRecordingStatus.paused);

      expect(updated.status, ActivityRecordingStatus.paused);
      expect(updated.activityType, ActivityType.run);
      expect(updated.startedAt, startedAt);
      expect(updated.endedAt, isNull);
      expect(updated.elapsedDurationSeconds, 0);
      expect(updated.points, isEmpty);
    });

    test('copyWith shares the track when it is not replaced', () {
      final point = ActivityTrackPoint(
        latitude: 41.1,
        longitude: -8.6,
        timestamp: DateTime.utc(2026, 5, 30, 10),
      );
      final state = ActivityRecordingState(
        status: ActivityRecordingStatus.recording,
        segments: [
          ActivityTrackSegment(points: [point]),
        ],
      );

      final ticked = state.copyWith(elapsedDurationSeconds: 1);

      expect(identical(ticked.points, state.points), isTrue);
      expect(identical(ticked.segments, state.segments), isTrue);
      expect(() => ticked.points.add(point), throwsUnsupportedError);

      final grown = state.addPoint(point);
      expect(identical(grown.points, state.points), isFalse);
      expect(grown.points, hasLength(2));
      expect(state.points, hasLength(1));
    });

    test('appendTrackRuns grows the last segment and keeps earlier ones', () {
      ActivityTrackPoint at(double latitude) => ActivityTrackPoint(
        latitude: latitude,
        longitude: -8.6,
        timestamp: DateTime.utc(2026, 5, 30, 10),
      );
      final state = ActivityRecordingState(
        status: ActivityRecordingStatus.recording,
        segments: [
          ActivityTrackSegment(points: [at(1)]),
          ActivityTrackSegment(points: [at(2)]),
        ],
      );
      final first = state.segments.first;
      final last = state.segments.last;

      final grown = state.appendTrackRuns([
        TrackRun([at(3), at(4)]),
        TrackRun([at(5)], startsNewSegment: true),
      ]);

      expect(grown.segments, hasLength(3));
      expect(identical(grown.segments.first, first), isTrue);
      expect(identical(grown.segments[1], last), isFalse);
      expect(grown.segments[1].points.map((p) => p.latitude), [2, 3, 4]);
      expect(grown.segments.last.points.map((p) => p.latitude), [5]);
      expect(grown.points.map((p) => p.latitude), [1, 2, 3, 4, 5]);
      // The source state is an unchanged snapshot.
      expect(state.points, hasLength(2));
      expect(last.points, hasLength(1));
      expect(identical(state.appendTrackRuns(const []), state), isTrue);
    });

    test('copyWith can update elapsed duration', () {
      final state = ActivityRecordingState(
        status: ActivityRecordingStatus.recording,
        elapsedDurationSeconds: 4,
      );

      final updated = state.copyWith(elapsedDurationSeconds: 5);

      expect(updated.elapsedDurationSeconds, 5);
    });

    test('copyWith can clear nullable fields', () {
      final state = ActivityRecordingState(
        activityType: ActivityType.ride,
        startedAt: DateTime.utc(2026),
        endedAt: DateTime.utc(2026, 5, 30),
        lastError: ActivityRecordingError.localSaveFailed,
      );

      final updated = state.copyWith(
        activityType: null,
        startedAt: null,
        endedAt: null,
        lastError: null,
      );

      expect(updated.activityType, isNull);
      expect(updated.startedAt, isNull);
      expect(updated.endedAt, isNull);
      expect(updated.lastError, isNull);
    });

    test('does not expose mutable point lists', () {
      final point = _point();
      final source = [point];
      final state = ActivityRecordingState(points: source);

      source.clear();

      expect(state.points, [point]);
      expect(() => state.points.add(_point()), throwsUnsupportedError);
    });

    test('does not expose mutable segment lists', () {
      final point = _point();
      final segment = ActivityTrackSegment(points: [point]);
      final source = [segment];
      final state = ActivityRecordingState(segments: source);

      source.clear();

      expect(state.segments, [segment]);
      expect(state.points, [point]);
      expect(
        () => state.segments.add(ActivityTrackSegment()),
        throwsUnsupportedError,
      );
      expect(
        () => state.segments.single.points.add(_point()),
        throwsUnsupportedError,
      );
    });

    test('supports completed state without points', () {
      final state = ActivityRecordingState(
        status: ActivityRecordingStatus.completed,
        startedAt: DateTime.utc(2026),
        endedAt: DateTime.utc(2026, 5, 30),
      );

      expect(state.status, ActivityRecordingStatus.completed);
      expect(state.points, isEmpty);
    });

    test('addPoint returns a new state', () {
      final point = _point();
      final state = ActivityRecordingState();

      final updated = state.addPoint(point);

      expect(state.points, isEmpty);
      expect(updated.points, [point]);
      expect(updated.segments, hasLength(1));
      expect(updated.segments.single.points, [point]);
    });

    test('startNewSegment preserves pause and resume boundaries', () {
      final firstPoint = _point(latitude: 41);
      final secondPoint = _point(latitude: 42);
      final state = ActivityRecordingState()
          .startNewSegment()
          .addPoint(firstPoint)
          .startNewSegment()
          .addPoint(secondPoint);

      expect(state.points, [firstPoint, secondPoint]);
      expect(state.segments, hasLength(2));
      expect(state.segments.first.points, [firstPoint]);
      expect(state.segments.last.points, [secondPoint]);
    });
  });
}

ActivityTrackPoint _point({double latitude = 41}) {
  return ActivityTrackPoint(
    latitude: latitude,
    longitude: -8,
    timestamp: DateTime.utc(2026),
  );
}
