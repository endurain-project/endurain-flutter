import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_gpx_builder.dart';
import 'package:endurain/features/activity/services/local_activity_summary_builder.dart';
import 'package:endurain/features/watch/models/watch_session_handoff.dart';
import 'package:endurain/features/watch/repositories/watch_ingestion_ledger.dart';

/// Outcome of ingesting a single [WatchSessionHandoff].
enum WatchIngestionOutcome {
  /// The session was converted to GPX and persisted as a local activity.
  ingested,

  /// A local activity for this watch session already exists. The handoff is
  /// still acknowledged so the watch can drop its copy.
  duplicate,

  /// The watch has not finished the session yet; leave it queued.
  incomplete,

  /// The session carried nothing at all: no points and no recorded duration
  /// (for example a workout started and immediately discarded). Nothing is
  /// lost by dropping it, so the handoff is acknowledged.
  empty,

  /// The session carried points, but none this app version can read (a newer
  /// point schema, say). Left queued, NOT acknowledged, so a later app version
  /// can still ingest it instead of the watch deleting the only copy.
  unreadable,

  /// The session has a recorded duration but no GPS track (an indoor or
  /// treadmill workout). The upload pipeline is GPX-only, so it cannot be
  /// stored yet; it is left queued, NOT acknowledged, so it survives until
  /// route-less sessions are supported instead of being silently dropped.
  noRoute,

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

  /// Whether the handoff may be dropped by the watch: only once it is stored,
  /// already stored, or provably empty. Everything else stays queued.
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
/// deterministically from the watch source and session id, and every ingested
/// id is kept in a [WatchIngestionLedger]. A re-delivered handoff is reported
/// as a duplicate instead of creating a second activity, even when the user
/// has since deleted the local record.
class WatchSessionIngestionService {
  WatchSessionIngestionService({
    required LocalActivityRepository repository,
    required WatchIngestionLedger ledger,
    ActivityGpxBuilder gpxBuilder = const ActivityGpxBuilder(),
    LocalActivitySummaryBuilder? summaryBuilder,
    DiagnosticsRecorder? diagnostics,
    DateTime Function()? now,
  }) : _repository = repository,
       _ledger = ledger,
       _gpxBuilder = gpxBuilder,
       _summaryBuilder = summaryBuilder ?? LocalActivitySummaryBuilder(),
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _now = now ?? DateTime.now;

  final LocalActivityRepository _repository;
  final WatchIngestionLedger _ledger;
  final ActivityGpxBuilder _gpxBuilder;
  final LocalActivitySummaryBuilder _summaryBuilder;
  final DiagnosticsRecorder _diagnostics;
  final DateTime Function() _now;

  /// Deterministic local activity id for a watch session.
  ///
  /// Restricted to the character set the GPX storage accepts so the record id
  /// and its file name stay in a one-to-one relationship. The encoding is
  /// injective: letters, digits, and `-` pass through, and every other UTF-16
  /// code unit (including `_` itself) becomes `_` plus four hex digits. Two
  /// distinct session ids therefore never share a local id, so one session
  /// can never be mistaken for a duplicate of another and dropped.
  static String localActivityIdFor(WatchSessionHandoff handoff) {
    final encoded = StringBuffer();
    for (final unit in handoff.sessionId.codeUnits) {
      if (_isPassthrough(unit)) {
        encoded.writeCharCode(unit);
      } else {
        encoded
          ..write('_')
          ..write(unit.toRadixString(16).padLeft(4, '0'));
      }
    }
    return 'watch_${handoff.source.name}_$encoded';
  }

  static bool _isPassthrough(int unit) =>
      (unit >= 0x30 && unit <= 0x39) || // 0-9
      (unit >= 0x41 && unit <= 0x5a) || // A-Z
      (unit >= 0x61 && unit <= 0x7a) || // a-z
      unit == 0x2d; // -

  Future<WatchIngestionResult> ingest(WatchSessionHandoff handoff) async {
    if (!handoff.isComplete) {
      return const WatchIngestionResult(WatchIngestionOutcome.incomplete);
    }

    final localActivityId = localActivityIdFor(handoff);
    try {
      if (await _ledger.contains(localActivityId)) {
        return WatchIngestionResult(
          WatchIngestionOutcome.duplicate,
          localActivityId: localActivityId,
        );
      }
      final existing = await _repository.get(localActivityId);
      if (existing != null) {
        // Stored by an earlier pass whose ledger write did not land; record it
        // now so a later deletion of the local record cannot re-import it.
        await _ledger.record(
          localActivityId,
          healthWorkoutId: handoff.healthWorkoutId,
        );
        return WatchIngestionResult(
          WatchIngestionOutcome.duplicate,
          localActivityId: localActivityId,
        );
      }

      final state = _stateFor(handoff, localActivityId);
      if (state.points.isEmpty) {
        final outcome = _outcomeForTracklessSession(handoff);
        _diagnostics.recordBreadcrumbSync(
          DiagnosticsEvents.watchSessionDeferred,
          details: {'source': handoff.source.name, 'reason': outcome.name},
        );
        return WatchIngestionResult(outcome);
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
      await _ledger.record(
        localActivityId,
        healthWorkoutId: handoff.healthWorkoutId,
      );

      // Sanitized breadcrumb only: counts and the watch platform, never
      // coordinates or device identifiers.
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.watchSessionIngested,
        details: {
          'source': handoff.source.name,
          'points': state.points.length,
          'dropped_points': handoff.droppedPointCount,
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

  /// Classifies a session that produced no track points.
  WatchIngestionOutcome _outcomeForTracklessSession(
    WatchSessionHandoff handoff,
  ) {
    if (handoff.droppedPointCount > 0) {
      return WatchIngestionOutcome.unreadable;
    }
    final session = handoff.session;
    final endedAt = session.endedAt;
    final hasDuration =
        session.elapsedDurationSeconds > 0 ||
        (endedAt != null && endedAt.isAfter(session.startedAt));
    return hasDuration
        ? WatchIngestionOutcome.noRoute
        : WatchIngestionOutcome.empty;
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
