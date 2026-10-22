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
    required this.isComplete,
    this.payloadVersion = currentPayloadVersion,
  });

  /// Schema version for handoff payloads. Bump when the envelope or either
  /// embedded model changes shape in a way older native builds cannot read.
  static const int currentPayloadVersion = 1;

  final WatchSource source;
  final ActiveActivitySession session;
  final List<RecordedActivityPoint> points;

  /// Whether the watch considers the session finished. Incomplete handoffs are
  /// never ingested: the watch keeps them queued and re-sends until it can send
  /// a complete one, so a partially-transferred workout can never be persisted
  /// as if it were the whole activity.
  final bool isComplete;

  final int payloadVersion;

  /// Stable identifier of the watch session, used for idempotent ingestion.
  String get sessionId => session.localSessionId;

  Map<String, Object?> toJson() {
    return {
      'version': payloadVersion,
      'source': source.toJson(),
      'complete': isComplete,
      'session': session.toJson(),
      'points': [for (final point in points) point.toJson()],
    };
  }

  /// Parses a handoff delivered by the native transport.
  ///
  /// Throws [FormatException] when the payload version is unsupported, the
  /// source is unknown, or the session envelope is malformed. Individual
  /// malformed points are skipped rather than failing the whole session, so one
  /// corrupt sample cannot cost the user a workout.
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

    return WatchSessionHandoff(
      source: source,
      session: ActiveActivitySession.fromJson(session),
      points: _parsePoints(json['points']),
      isComplete: json['complete'] == true,
      payloadVersion: version,
    );
  }

  static List<RecordedActivityPoint> _parsePoints(Object? value) {
    if (value is! List) {
      return const <RecordedActivityPoint>[];
    }
    final points = <RecordedActivityPoint>[];
    for (final entry in value) {
      if (entry is! Map) {
        continue;
      }
      try {
        points.add(RecordedActivityPoint.fromJson(entry));
      } on FormatException {
        continue;
      }
    }
    return points;
  }
}
