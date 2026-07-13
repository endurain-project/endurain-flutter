import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';

/// Typed, language-free recorder failure reasons.
///
/// The UI layer is responsible for mapping these to localized error text; the
/// recorder contract never emits user-facing strings.
enum ActivityRecorderFailureReason {
  locationStreamFailed,
  locationUnavailable,
  permissionLost,
  persistenceFailed,
  unsupportedPlatform,
}

/// The kind of [ActivityRecorderEvent] emitted by an [ActivityLocationRecorder].
enum ActivityRecorderEventType {
  started,
  pointBatchAvailable,
  paused,
  resumed,
  stopped,
  failed,
  recoverableStateChanged,
}

/// An event emitted by an [ActivityLocationRecorder].
///
/// Events stay free of localized text. Point batches carry already-persisted
/// [RecordedActivityPoint]s so Flutter can render and aggregate without owning
/// the only copy of the data.
class ActivityRecorderEvent {
  const ActivityRecorderEvent({
    required this.type,
    this.session,
    this.points = const <RecordedActivityPoint>[],
    this.failureReason,
  });

  const ActivityRecorderEvent.started(ActiveActivitySession session)
    : this(type: ActivityRecorderEventType.started, session: session);

  const ActivityRecorderEvent.pointBatchAvailable(
    List<RecordedActivityPoint> points,
  ) : this(type: ActivityRecorderEventType.pointBatchAvailable, points: points);

  const ActivityRecorderEvent.paused(ActiveActivitySession session)
    : this(type: ActivityRecorderEventType.paused, session: session);

  const ActivityRecorderEvent.resumed(ActiveActivitySession session)
    : this(type: ActivityRecorderEventType.resumed, session: session);

  const ActivityRecorderEvent.stopped(ActiveActivitySession session)
    : this(type: ActivityRecorderEventType.stopped, session: session);

  const ActivityRecorderEvent.failed(ActivityRecorderFailureReason reason)
    : this(type: ActivityRecorderEventType.failed, failureReason: reason);

  const ActivityRecorderEvent.recoverableStateChanged(
    ActiveActivitySession? session,
  ) : this(
        type: ActivityRecorderEventType.recoverableStateChanged,
        session: session,
      );

  final ActivityRecorderEventType type;
  final ActiveActivitySession? session;
  final List<RecordedActivityPoint> points;
  final ActivityRecorderFailureReason? failureReason;
}

/// Request used to start a new recording through an [ActivityLocationRecorder].
class ActivityRecorderStartRequest {
  const ActivityRecorderStartRequest({
    required this.localSessionId,
    required this.activityType,
    required this.startedAt,
    this.connectionOrigin,
    this.connectionProfileId,
    this.backgroundConfig,
  });

  final String localSessionId;
  final ActivityType activityType;
  final DateTime startedAt;
  final String? connectionOrigin;
  final String? connectionProfileId;
  final BackgroundLocationConfig? backgroundConfig;
}

/// Abstraction over the platform mechanism that collects and persists location
/// points for an active recording.
///
/// Implementations may be a foreground Dart stream (development/fallback) or a
/// native background recorder. They must persist points durably before
/// emitting [ActivityRecorderEventType.pointBatchAvailable], so the Flutter
/// isolate is never the only owner of active-recording data.
abstract class ActivityLocationRecorder {
  /// Broadcast stream of recorder events.
  Stream<ActivityRecorderEvent> get events;

  /// Begins collecting and persisting points for [request].
  Future<void> start(ActivityRecorderStartRequest request);

  /// Pauses collection while keeping the active session recoverable.
  Future<void> pause();

  /// Resumes collection, starting a new track segment.
  Future<void> resume();

  /// Stops collection and marks the active session as completed.
  Future<void> stop();

  /// Cancels collection and clears the active session and its points.
  Future<void> discard();

  /// Returns persisted points from [sinceOffset] for incremental syncing.
  Future<List<RecordedActivityPoint>> drain({int sinceOffset = 0});

  /// Returns a recoverable active session if one exists, otherwise `null`.
  Future<ActiveActivitySession?> recoverActiveSession();

  /// Releases resources held by the recorder.
  Future<void> dispose();
}
