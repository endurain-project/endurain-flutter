import 'dart:async';

import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';

/// Folds the recorder's point batches into the live [ActivityRecordingState],
/// reconciling them with the recorder's stored-entry offsets so that no point
/// is applied twice and gaps (batches missed while backgrounded) are drained.
class RecordingPointBatcher {
  RecordingPointBatcher({
    required ActivityLocationRecorder recorder,
    required ActivityTrackPoint Function(RecordedActivityPoint) toTrackPoint,
    required ActivityRecordingState Function() readState,
    required void Function(ActivityRecordingState) emit,
    required bool Function(String? sessionId) isCurrentSession,
    required void Function(Object error, StackTrace stackTrace) onSaveFailed,
    required void Function() onSaveGap,
    required void Function(int pointCount) onApplied,
  }) : _recorder = recorder,
       _toTrackPoint = toTrackPoint,
       _readState = readState,
       _emit = emit,
       _isCurrentSession = isCurrentSession,
       _onSaveFailed = onSaveFailed,
       _onSaveGap = onSaveGap,
       _onApplied = onApplied;

  final ActivityLocationRecorder _recorder;
  final ActivityTrackPoint Function(RecordedActivityPoint) _toTrackPoint;
  final ActivityRecordingState Function() _readState;
  final void Function(ActivityRecordingState) _emit;
  final bool Function(String? sessionId) _isCurrentSession;
  final void Function(Object error, StackTrace stackTrace) _onSaveFailed;
  final void Function() _onSaveGap;
  final void Function(int pointCount) _onApplied;

  Future<void> _queue = Future<void>.value();
  int _nextPointOffset = 0;
  int? _lastRecordedSegmentIndex;

  /// Forgets all offsets, for a new or discarded recording.
  void reset() {
    _nextPointOffset = 0;
    _lastRecordedSegmentIndex = null;
  }

  /// Resumes from a recovered recording that already holds [recordedPoints].
  void restore(List<RecordedActivityPoint> recordedPoints) {
    _nextPointOffset = recordedPoints.length;
    _lastRecordedSegmentIndex = recordedPoints.lastOrNull?.segmentIndex;
  }

  /// Batches are applied strictly in arrival order.
  void enqueue(ActivityRecorderEvent event) {
    _queue = _queue.then((_) => _handlePointBatch(event));
  }

  Future<void> _handlePointBatch(ActivityRecorderEvent event) async {
    final pointOffset = event.pointOffset;
    final sessionId = event.localSessionId;
    if (!_isLiveFor(sessionId) || pointOffset == null || pointOffset < 0) {
      return;
    }
    try {
      if (pointOffset > _nextPointOffset) {
        final offset = _nextPointOffset;
        final points = await _recorder.drain(sinceOffset: offset);
        // A pause or stop that landed during the drain leaves the gap for the
        // next batch or the final drain; it is not a save failure.
        if (!_isLiveFor(sessionId)) {
          return;
        }
        _apply(points, pointOffset: offset);
      }
      if (pointOffset <= _nextPointOffset) {
        _apply(event.points, pointOffset: pointOffset);
      } else {
        _onSaveGap();
      }
    } catch (error, stackTrace) {
      if (_isCurrentSession(sessionId)) {
        _onSaveFailed(error, stackTrace);
      }
    }
  }

  bool _isLiveFor(String? sessionId) =>
      _isCurrentSession(sessionId) &&
      _readState().status == ActivityRecordingStatus.recording;

  void _apply(List<RecordedActivityPoint> points, {required int pointOffset}) {
    // Offsets count the recorder's stored entries, which can exceed the
    // parsed points when a malformed entry was skipped.
    final sourceCount = RecordedActivityPointBatch.sourceCountOf(points);
    final state = _readState();
    if (state.status != ActivityRecordingStatus.recording || sourceCount == 0) {
      return;
    }
    final skipCount = _nextPointOffset - pointOffset;
    if (skipCount < 0 || skipCount >= sourceCount) {
      return;
    }
    // Trim the overlap by stored-entry index, not by parsed position: a
    // skipped entry before the cut would otherwise shift it by one.
    final sourceIndices = RecordedActivityPointBatch.sourceIndicesOf(points);
    final newPoints = <RecordedActivityPoint>[
      for (var i = 0; i < points.length; i++)
        if (sourceIndices[i] >= skipCount) points[i],
    ];
    _nextPointOffset = pointOffset + sourceCount;
    if (newPoints.isEmpty) {
      return;
    }

    // Apply the whole batch with a single state emission: a background drain
    // can deliver hundreds of points at once. Appending to the last segment
    // keeps the cost proportional to the batch, not to the whole track.
    final runs = <TrackRun>[];
    var current = <ActivityTrackPoint>[];
    var startsNewSegment = false;
    var segmentHasPoints =
        state.segments.lastOrNull?.points.isNotEmpty ?? false;
    for (final recordedPoint in newPoints) {
      if (_lastRecordedSegmentIndex != recordedPoint.segmentIndex &&
          segmentHasPoints) {
        if (current.isNotEmpty) {
          runs.add(TrackRun(current, startsNewSegment: startsNewSegment));
        }
        current = <ActivityTrackPoint>[];
        startsNewSegment = true;
      }
      current.add(_toTrackPoint(recordedPoint));
      segmentHasPoints = true;
      _lastRecordedSegmentIndex = recordedPoint.segmentIndex;
    }
    runs.add(TrackRun(current, startsNewSegment: startsNewSegment));
    final updated = state.appendTrackRuns(runs);
    _emit(updated);
    _onApplied(updated.points.length);
  }

  /// Groups [points] into one segment per change of segment index.
  List<ActivityTrackSegment> segmentsFromRecorded(
    List<RecordedActivityPoint> points,
  ) {
    if (points.isEmpty) {
      return [ActivityTrackSegment()];
    }
    final segments = <ActivityTrackSegment>[];
    var currentSegmentIndex = points.first.segmentIndex;
    var currentPoints = <ActivityTrackPoint>[];
    for (final point in points) {
      if (point.segmentIndex != currentSegmentIndex &&
          currentPoints.isNotEmpty) {
        segments.add(ActivityTrackSegment(points: currentPoints));
        currentPoints = <ActivityTrackPoint>[];
        currentSegmentIndex = point.segmentIndex;
      }
      currentPoints.add(_toTrackPoint(point));
    }
    if (currentPoints.isNotEmpty) {
      segments.add(ActivityTrackSegment(points: currentPoints));
    }
    return segments;
  }
}
