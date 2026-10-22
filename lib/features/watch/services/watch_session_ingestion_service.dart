import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_gpx_builder.dart';
import 'package:endurain/features/activity/services/local_activity_summary_builder.dart';
import 'package:endurain/features/watch/models/watch_session_handoff.dart';

/// Outcome of ingesting a single [WatchSessionHandoff].
enum WatchIngestionOutcome {
  /// The session was converted to GPX and persisted as a local activity.
  ingested,

  /// A local activity for this watch session already exists. The handoff is
  /// still acknowledged so the watch can drop its copy.
  duplicate,

  /// The watch has not finished the session yet; leave it queued.
  incomplete,

  /// The session carried no usable track points; nothing to persist. The
  /// handoff is acknowledged so it does not block the queue forever.
  empty,

  /// Persisting failed. The handoff must NOT be acknowledged so the watch
  /// re-delivers it later.
  failed,
}

/// Result of one ingestion attempt.
class WatchIngestionResult {
  const WatchIngestionResult(this.outcome, {this.localActivityId, this.error});

  final WatchIngestionOutcome outcome;
  final String? localActivityId;
  final AppException? error;

  /// Whether the handoff may be dropped by the watch. Everything except a
  /// hard failure and a still-incomplete session is terminal.
  bool get isAcknowledgeable =>
      outcome == WatchIngestionOutcome.ingested ||
      outcome == WatchIngestionOutcome.duplicate ||
      outcome == WatchIngestionOutcome.empty;
}

/// Converts a watch-recorded session into the phone's existing activity
/// representation: a GPX file plus a `LocalActivityRecord` with a `pending`
/// upload status, which the durable upload queue then drains.
///
/// Ingestion is **idempotent**: the local activity id is derived
/// deterministically from the watch source and session id, so a re-delivered
/// handoff resolves to the same record and is reported as a duplicate instead
/// of creating a second activity.
class WatchSessionIngestionService {
  WatchSessionIngestionService({
    required LocalActivityRepository repository,
    ActivityGpxBuilder gpxBuilder = const ActivityGpxBuilder(),
    LocalActivitySummaryBuilder? summaryBuilder,
    DiagnosticsRecorder? diagnostics,
    DateTime Function()? now,
  }) : _repository = repository,
       _gpxBuilder = gpxBuilder,
       _summaryBuilder = summaryBuilder ?? LocalActivitySummaryBuilder(),
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _now = now ?? DateTime.now;

  final LocalActivityRepository _repository;
  final ActivityGpxBuilder _gpxBuilder;
  final LocalActivitySummaryBuilder _summaryBuilder;
  final DiagnosticsRecorder _diagnostics;
  final DateTime Function() _now;

  /// Deterministic local activity id for a watch session.
  ///
  /// Restricted to the character set the GPX storage accepts so the record id
  /// and its file name stay in a one-to-one relationship.
  static String localActivityIdFor(WatchSessionHandoff handoff) {
    final sanitizedSessionId = handoff.sessionId.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    return 'watch_${handoff.source.name}_$sanitizedSessionId';
  }

  Future<WatchIngestionResult> ingest(WatchSessionHandoff handoff) async {
    if (!handoff.isComplete) {
      return const WatchIngestionResult(WatchIngestionOutcome.incomplete);
    }

    final localActivityId = localActivityIdFor(handoff);
    try {
      final existing = await _repository.get(localActivityId);
      if (existing != null) {
        return WatchIngestionResult(
          WatchIngestionOutcome.duplicate,
          localActivityId: localActivityId,
        );
      }

      final state = _stateFor(handoff, localActivityId);
      if (state.points.isEmpty) {
        return const WatchIngestionResult(WatchIngestionOutcome.empty);
      }

      final createdAt = _now().toUtc();
      final gpxFileName = await _repository.writeGpx(
        id: localActivityId,
        gpx: _gpxBuilder.build(state),
      );
      final record = _summaryBuilder
          .build(
            state: state,
            id: localActivityId,
            gpxFileName: gpxFileName,
            createdAt: createdAt,
          )
          .copyWith(
            connectionOrigin: handoff.session.connectionOrigin,
            connectionProfileId: handoff.session.connectionProfileId,
          );
      await _repository.upsert(record);

      // Sanitized breadcrumb only: counts and the watch platform, never
      // coordinates or device identifiers.
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.watchSessionIngested,
        details: {
          'source': handoff.source.name,
          'points': state.points.length,
        },
      );
      return WatchIngestionResult(
        WatchIngestionOutcome.ingested,
        localActivityId: localActivityId,
      );
    } catch (error) {
      final appError = error is AppException
          ? error
          : AppException(AppErrorCode.activityLocalSaveFailed, cause: error);
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.watchSessionIngestFailed,
        details: {
          'source': handoff.source.name,
          'type': error.runtimeType.toString(),
        },
      );
      return WatchIngestionResult(
        WatchIngestionOutcome.failed,
        localActivityId: localActivityId,
        error: appError,
      );
    }
  }

  /// Rebuilds the completed recording state the GPX and summary builders
  /// expect, reusing the same segment semantics as the phone recorders:
  /// consecutive points sharing a [RecordedActivityPoint.segmentIndex] form one
  /// track segment, so pauses and gaps stay visible as track breaks.
  ActivityRecordingState _stateFor(
    WatchSessionHandoff handoff,
    String localActivityId,
  ) {
    final session = handoff.session;
    final segments = _segmentsFrom(handoff.points);
    final startedAt = session.startedAt;
    var endedAt = session.endedAt;
    if (endedAt == null && handoff.points.isNotEmpty) {
      endedAt = handoff.points.last.timestamp;
    }

    return ActivityRecordingState(
      status: ActivityRecordingStatus.completed,
      activityType: session.activityType,
      startedAt: startedAt,
      endedAt: endedAt,
      localActivityId: localActivityId,
      elapsedDurationSeconds: session.elapsedDurationSeconds,
      segments: segments,
    );
  }

  List<ActivityTrackSegment> _segmentsFrom(List<RecordedActivityPoint> points) {
    if (points.isEmpty) {
      return const <ActivityTrackSegment>[];
    }
    final segments = <ActivityTrackSegment>[];
    var currentSegmentIndex = points.first.segmentIndex;
    var currentPoints = <ActivityTrackPoint>[];
    for (final point in points) {
      if (point.segmentIndex != currentSegmentIndex &&
          currentPoints.isNotEmpty) {
        segments.add(ActivityTrackSegment(points: currentPoints));
        currentPoints = <ActivityTrackPoint>[];
      }
      currentSegmentIndex = point.segmentIndex;
      currentPoints.add(point.toTrackPoint());
    }
    if (currentPoints.isNotEmpty) {
      segments.add(ActivityTrackSegment(points: currentPoints));
    }
    return segments;
  }
}
