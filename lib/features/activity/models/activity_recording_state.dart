import 'package:endurain/core/utils/copy_with.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/append_only_list.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';

/// Ephemeral UI/recording status used by [ActivityRecordingState], the live
/// state pushed to the controller/screen during a session. The durable,
/// persisted counterpart is `ActiveActivityStatus` in
/// `active_activity_session.dart` (which has no `idle` — sessions only exist
/// once recording has begun); both intentionally stay separate so the
/// ephemeral UI model and the recoverable persisted model can evolve apart.
enum ActivityRecordingStatus {
  idle,
  recording,
  paused,
  stopping,
  completed,
  failed,
}

/// Consecutive points to append to a recording's track: they continue the last
/// segment, or open a new one when [startsNewSegment] is set.
class TrackRun {
  const TrackRun(this.points, {this.startsNewSegment = false});

  final List<ActivityTrackPoint> points;
  final bool startsNewSegment;
}

class ActivityRecordingState {
  ActivityRecordingState({
    this.status = ActivityRecordingStatus.idle,
    this.activityType,
    this.startedAt,
    this.endedAt,
    this.localActivityId,
    this.lastError,
    this.elapsedDurationSeconds = 0,
    this.currentHeartRateBpm,
    this.currentPowerWatts,
    this.currentCadenceRpm,
    this.isAutoPaused = false,
    List<ActivityTrackPoint> points = const [],
    List<ActivityTrackSegment> segments = const [],
  }) : _segments = _frozenSegments(points, segments),
       _points = _frozenPoints(points, segments);

  /// Takes the track as already-frozen lists, so [copyWith] can share them
  /// with the source state instead of copying them again.
  ActivityRecordingState._({
    required this.status,
    required this.activityType,
    required this.startedAt,
    required this.endedAt,
    required this.localActivityId,
    required this.lastError,
    required this.elapsedDurationSeconds,
    required this.currentHeartRateBpm,
    required this.currentPowerWatts,
    required this.currentCadenceRpm,
    required this.isAutoPaused,
    required AppendOnlyList<ActivityTrackPoint> frozenPoints,
    required List<ActivityTrackSegment> frozenSegments,
  }) : _points = frozenPoints,
       _segments = frozenSegments;

  final ActivityRecordingStatus status;
  final ActivityType? activityType;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? localActivityId;
  final ActivityRecordingError? lastError;
  final int elapsedDurationSeconds;

  /// Most recent live heart rate (bpm) from a connected sensor, updated as
  /// readings arrive rather than only when a GPS point is recorded. `null` when
  /// no live heart-rate stream is feeding the recording (e.g. Android, where
  /// the native recorder stamps heart rate onto points instead). Surfaced live
  /// while recording; the durable per-point heart rate still lives on the
  /// track points.
  final int? currentHeartRateBpm;

  /// Most recent live power (watts) from a connected power meter, updated as
  /// readings arrive rather than only when a GPS point is recorded. `null` when
  /// no live power stream is feeding the recording. Surfaced live while
  /// recording; the durable per-point power still lives on the track points.
  final int? currentPowerWatts;

  /// Most recent live cadence (rpm) from a connected cadence sensor, updated as
  /// readings arrive rather than only when a GPS point is recorded. `null` when
  /// no live cadence stream is feeding the recording. Surfaced live while
  /// recording; the durable per-point cadence still lives on the track points.
  final int? currentCadenceRpm;

  /// Whether the recording is currently paused automatically by the
  /// movement/auto-pause detector, as opposed to an explicit user pause.
  /// Only meaningful when [status] is [ActivityRecordingStatus.paused]; the
  /// UI uses this to show a distinct "auto-paused" indicator and to know
  /// that this pause may resume on its own once movement is detected again.
  final bool isAutoPaused;

  final AppendOnlyList<ActivityTrackPoint> _points;
  final List<ActivityTrackSegment> _segments;

  /// The track points, unmodifiable. The same list instance is returned for
  /// as long as the track is unchanged, also across [copyWith] calls that do
  /// not replace it, so callers can cache work derived from it by identity.
  List<ActivityTrackPoint> get points => _points;

  /// The track segments, unmodifiable and identity-stable like [points].
  ///
  /// Contract for caches keyed by identity: a segment instance never changes,
  /// and a segment that gained points is a new instance (see
  /// [ActivityTrackSegment]), while untouched segments keep their instance
  /// across [appendTrackRuns], [addPoint] and [startNewSegment].
  List<ActivityTrackSegment> get segments => _segments;

  bool get isActive {
    return status == ActivityRecordingStatus.recording ||
        status == ActivityRecordingStatus.paused;
  }

  bool get canRecover =>
      status == ActivityRecordingStatus.failed &&
      startedAt != null &&
      lastError != ActivityRecordingError.emptyRecording;

  ActivityRecordingState copyWith({
    ActivityRecordingStatus? status,
    Object? activityType = kUnset,
    Object? startedAt = kUnset,
    Object? endedAt = kUnset,
    Object? localActivityId = kUnset,
    Object? lastError = kUnset,
    int? elapsedDurationSeconds,
    Object? currentHeartRateBpm = kUnset,
    Object? currentPowerWatts = kUnset,
    Object? currentCadenceRpm = kUnset,
    bool? isAutoPaused,
    List<ActivityTrackPoint>? points,
    List<ActivityTrackSegment>? segments,
  }) {
    // Share the frozen track when it is unchanged: the 1 Hz elapsed tick and
    // live sensor updates must not re-copy every recorded point.
    final keepsTrack = points == null && segments == null;
    final newPoints = points ?? _points;
    final newSegments = segments ?? (points == null ? _segments : const []);
    return ActivityRecordingState._(
      status: status ?? this.status,
      activityType: identical(activityType, kUnset)
          ? this.activityType
          : activityType as ActivityType?,
      startedAt: identical(startedAt, kUnset)
          ? this.startedAt
          : startedAt as DateTime?,
      endedAt: identical(endedAt, kUnset) ? this.endedAt : endedAt as DateTime?,
      localActivityId: identical(localActivityId, kUnset)
          ? this.localActivityId
          : localActivityId as String?,
      lastError: identical(lastError, kUnset)
          ? this.lastError
          : lastError as ActivityRecordingError?,
      elapsedDurationSeconds:
          elapsedDurationSeconds ?? this.elapsedDurationSeconds,
      currentHeartRateBpm: identical(currentHeartRateBpm, kUnset)
          ? this.currentHeartRateBpm
          : currentHeartRateBpm as int?,
      currentPowerWatts: identical(currentPowerWatts, kUnset)
          ? this.currentPowerWatts
          : currentPowerWatts as int?,
      currentCadenceRpm: identical(currentCadenceRpm, kUnset)
          ? this.currentCadenceRpm
          : currentCadenceRpm as int?,
      isAutoPaused: isAutoPaused ?? this.isAutoPaused,
      frozenPoints: keepsTrack
          ? _points
          : _frozenPoints(newPoints, newSegments),
      frozenSegments: keepsTrack
          ? _segments
          : _frozenSegments(newPoints, newSegments),
    );
  }

  ActivityRecordingState addPoint(ActivityTrackPoint point) => appendTrackRuns([
    TrackRun([point]),
  ]);

  /// Appends points to the track without copying the existing ones, in time
  /// proportional to the points added (plus the segment count).
  ///
  /// Each [TrackRun] either continues the last segment or opens a new one.
  /// Only the segments that receive points change identity.
  ActivityRecordingState appendTrackRuns(List<TrackRun> runs) {
    var segments = _segments;
    final added = <ActivityTrackPoint>[];
    for (final run in runs) {
      if (run.points.isEmpty) {
        continue;
      }
      added.addAll(run.points);
      if (run.startsNewSegment || segments.isEmpty) {
        segments = [...segments, ActivityTrackSegment(points: run.points)];
      } else {
        segments = [
          ...segments.take(segments.length - 1),
          segments.last.addPoints(run.points),
        ];
      }
    }
    if (added.isEmpty) {
      return this;
    }
    return _withTrack(
      _points.appended(added),
      List<ActivityTrackSegment>.unmodifiable(segments),
    );
  }

  ActivityRecordingState startNewSegment() {
    return _withTrack(
      _points,
      List<ActivityTrackSegment>.unmodifiable([
        ..._segments,
        ActivityTrackSegment(),
      ]),
    );
  }

  ActivityRecordingState _withTrack(
    AppendOnlyList<ActivityTrackPoint> points,
    List<ActivityTrackSegment> segments,
  ) {
    return ActivityRecordingState._(
      status: status,
      activityType: activityType,
      startedAt: startedAt,
      endedAt: endedAt,
      localActivityId: localActivityId,
      lastError: lastError,
      elapsedDurationSeconds: elapsedDurationSeconds,
      currentHeartRateBpm: currentHeartRateBpm,
      currentPowerWatts: currentPowerWatts,
      currentCadenceRpm: currentCadenceRpm,
      isAutoPaused: isAutoPaused,
      frozenPoints: points,
      frozenSegments: segments,
    );
  }

  /// The current live value for [kind], or `null` when none has been reported.
  int? currentSensorValue(RecordedSensorKind kind) {
    return switch (kind) {
      RecordedSensorKind.heartRate => currentHeartRateBpm,
      RecordedSensorKind.power => currentPowerWatts,
      RecordedSensorKind.cadence => currentCadenceRpm,
    };
  }

  /// Returns a copy with the live value for [kind] set to [value].
  ActivityRecordingState withCurrentSensorValue(
    RecordedSensorKind kind,
    int value,
  ) {
    return switch (kind) {
      RecordedSensorKind.heartRate => copyWith(currentHeartRateBpm: value),
      RecordedSensorKind.power => copyWith(currentPowerWatts: value),
      RecordedSensorKind.cadence => copyWith(currentCadenceRpm: value),
    };
  }

  static List<ActivityTrackSegment> _frozenSegments(
    List<ActivityTrackPoint> points,
    List<ActivityTrackSegment> segments,
  ) {
    return List<ActivityTrackSegment>.unmodifiable(
      segments.isEmpty ? _segmentsFromPoints(points) : segments,
    );
  }

  static AppendOnlyList<ActivityTrackPoint> _frozenPoints(
    List<ActivityTrackPoint> points,
    List<ActivityTrackSegment> segments,
  ) {
    return AppendOnlyList<ActivityTrackPoint>.of(
      segments.isEmpty ? points : _flattenSegments(segments),
    );
  }

  static List<ActivityTrackSegment> _segmentsFromPoints(
    List<ActivityTrackPoint> points,
  ) {
    if (points.isEmpty) {
      return const [];
    }
    return [ActivityTrackSegment(points: points)];
  }

  static List<ActivityTrackPoint> _flattenSegments(
    List<ActivityTrackSegment> segments,
  ) {
    return [for (final segment in segments) ...segment.points];
  }
}
