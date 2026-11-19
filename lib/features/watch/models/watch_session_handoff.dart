import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';

/// Which watch platform produced a handoff.
///
/// Kept explicit (rather than inferred from the host platform) so the value
/// survives serialization and can be part of the deterministic local activity
/// id, keeping ids from two platforms from ever colliding.
enum WatchSource {
  appleWatch,
  wearOs;

  static WatchSource? tryFromJson(Object? value) {
    for (final source in WatchSource.values) {
      if (source.name == value) {
        return source;
      }
    }
    return null;
  }

  String toJson() => name;
}

/// One watch-recorded session handed to the phone for ingestion.
///
/// The envelope deliberately reuses [ActiveActivitySession] and
/// [RecordedActivityPoint] — the same models the native phone recorders
/// produce — so a watch session flows into the existing GPX, local-storage,
/// and upload pipeline without a parallel schema.
///
/// [payloadVersion] mirrors `NativeActivityRecorderChannelContract`: the native
/// side must reject or migrate mismatched versions rather than guessing.
class WatchSessionHandoff {
  const WatchSessionHandoff({
    required this.source,
    required this.session,
    required this.points,
    this.droppedPointCount = 0,
    this.healthWorkoutId,
    this.payloadVersion = currentPayloadVersion,
  });

  /// Schema version for handoff payloads. Bump when the envelope or either
  /// embedded model changes shape in a way older native builds cannot read.
  static const int currentPayloadVersion = 1;

  final WatchSource source;
  final ActiveActivitySession session;
  final List<RecordedActivityPoint> points;

  /// How many point entries the payload carried that could not be parsed.
  ///
  /// Distinguishes "the watch sent no points" from "the watch sent points this
  /// app version cannot read": only the first is safe to acknowledge when
  /// [points] ends up empty.
  final int droppedPointCount;

  /// Identifier of the workout the watch also saved to the health platform
  /// (the HealthKit `HKWorkout` UUID or the Health Connect record id), when it
  /// saved one.
  ///
  /// Lets Health Sync skip that workout so the same session is not imported a
  /// second time from the health platform.
  final String? healthWorkoutId;

  final int payloadVersion;

  /// Stable identifier of the watch session, used for idempotent ingestion.
  String get sessionId => session.localSessionId;

  /// Whether the watch considers the session finished. Incomplete handoffs are
  /// never ingested: the watch keeps them queued and re-sends until it can send
  /// a complete one, so a partially-transferred workout can never be persisted
  /// as if it were the whole activity.
  ///
  /// Derived from the session status so the envelope has a single source of
  /// truth for completion.
  bool get isComplete => session.status == ActiveActivityStatus.completed;

  Map<String, Object?> toJson() {
    return {
      'version': payloadVersion,
      'source': source.toJson(),
      'session': session.toJson(),
      'points': [for (final point in points) point.toJson()],
      if (healthWorkoutId != null) 'healthWorkoutId': healthWorkoutId,
    };
  }

  /// Parses a handoff delivered by the native transport.
  ///
  /// Throws [FormatException] when the payload version is unsupported, the
  /// source is unknown, or the session envelope is malformed. Individual
  /// malformed points are skipped and counted in [droppedPointCount] rather
  /// than failing the whole session, so one corrupt sample cannot cost the
  /// user a workout.
  factory WatchSessionHandoff.fromJson(Map<dynamic, dynamic> json) {
    final version = json['version'];
    if (version is! int) {
      throw const FormatException('Missing watch handoff field: version');
    }
    if (version != currentPayloadVersion) {
      throw FormatException('Unsupported watch handoff version: $version');
    }
    final source = WatchSource.tryFromJson(json['source']);
    if (source == null) {
      throw const FormatException('Unknown watch handoff source');
    }
    final session = json['session'];
    if (session is! Map) {
      throw const FormatException('Missing watch handoff field: session');
    }
    final healthWorkoutId = json['healthWorkoutId'];

    final parsed = _parsePoints(json['points']);
    return WatchSessionHandoff(
      source: source,
      session: ActiveActivitySession.fromJson(session),
      points: parsed.points,
      droppedPointCount: parsed.dropped,
      healthWorkoutId: healthWorkoutId is String && healthWorkoutId.isNotEmpty
          ? healthWorkoutId
          : null,
      payloadVersion: version,
    );
  }

  static ({List<RecordedActivityPoint> points, int dropped}) _parsePoints(
    Object? value,
  ) {
    if (value is! List) {
      return (points: const <RecordedActivityPoint>[], dropped: 0);
    }
    final points = <RecordedActivityPoint>[];
    var dropped = 0;
    for (final entry in value) {
      if (entry is! Map) {
        dropped++;
        continue;
      }
      try {
        points.add(RecordedActivityPoint.fromJson(entry));
      } on FormatException {
        dropped++;
      }
    }
    return (points: points, dropped: dropped);
  }
}
