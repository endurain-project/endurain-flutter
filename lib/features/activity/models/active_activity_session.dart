// Recording type relationships (controller -> service -> recorder):
// the durable session model survives app restarts; the ephemeral state model
// drives the live UI.

import 'package:endurain/core/utils/copy_with.dart';
import 'package:endurain/core/utils/json_parsing.dart';
import 'package:endurain/features/activity/models/activity_type.dart';

/// Lifecycle status of an active (in-progress or recoverable) recording.
///
/// This is intentionally independent from any UI display strings so the model
/// can be persisted and recovered without coupling to localization. The
/// ephemeral UI counterpart is `ActivityRecordingStatus` in
/// `activity_recording_state.dart` (which adds an `idle` value for the
/// pre-recording screen); they are kept separate so the durable session model
/// and the live UI model can evolve independently.
enum ActiveActivityStatus {
  recording,
  paused,
  stopping,
  completed,
  failed;

  static ActiveActivityStatus fromJson(Object? value) {
    return switch (value) {
      'recording' => ActiveActivityStatus.recording,
      'paused' => ActiveActivityStatus.paused,
      'stopping' => ActiveActivityStatus.stopping,
      'completed' => ActiveActivityStatus.completed,
      'failed' => ActiveActivityStatus.failed,
      _ => ActiveActivityStatus.failed,
    };
  }

  String toJson() => name;
}

/// Durable metadata for an active recording.
///
/// Raw track points are stored separately (see `RecordedActivityPoint`); this
/// model only carries the session bookkeeping needed to resume or recover a
/// recording after the Flutter isolate is paused, killed, or restarted.
class ActiveActivitySession {
  const ActiveActivitySession({
    required this.localSessionId,
    required this.activityType,
    required this.status,
    required this.startedAt,
    this.resumedAt,
    this.pausedAt,
    this.endedAt,
    this.elapsedDurationSeconds = 0,
    this.currentSegmentIndex = 0,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final String localSessionId;
  final ActivityType activityType;
  final ActiveActivityStatus status;
  final DateTime startedAt;
  final DateTime? resumedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final int elapsedDurationSeconds;
  final int currentSegmentIndex;
  final int schemaVersion;

  bool get isActive =>
      status == ActiveActivityStatus.recording ||
      status == ActiveActivityStatus.paused;

  ActiveActivitySession copyWith({
    String? localSessionId,
    ActivityType? activityType,
    ActiveActivityStatus? status,
    DateTime? startedAt,
    Object? resumedAt = kUnset,
    Object? pausedAt = kUnset,
    Object? endedAt = kUnset,
    int? elapsedDurationSeconds,
    int? currentSegmentIndex,
    int? schemaVersion,
  }) {
    return ActiveActivitySession(
      localSessionId: localSessionId ?? this.localSessionId,
      activityType: activityType ?? this.activityType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      resumedAt: identical(resumedAt, kUnset)
          ? this.resumedAt
          : resumedAt as DateTime?,
      pausedAt: identical(pausedAt, kUnset)
          ? this.pausedAt
          : pausedAt as DateTime?,
      endedAt: identical(endedAt, kUnset) ? this.endedAt : endedAt as DateTime?,
      elapsedDurationSeconds:
          elapsedDurationSeconds ?? this.elapsedDurationSeconds,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'localSessionId': localSessionId,
      'activityType': activityType.apiValue,
      'status': status.toJson(),
      'startedAt': startedAt.toUtcIso8601(),
      if (resumedAt != null) 'resumedAt': resumedAt!.toUtcIso8601(),
      if (pausedAt != null) 'pausedAt': pausedAt!.toUtcIso8601(),
      if (endedAt != null) 'endedAt': endedAt!.toUtcIso8601(),
      'elapsedDurationSeconds': elapsedDurationSeconds,
      'currentSegmentIndex': currentSegmentIndex,
    };
  }

  factory ActiveActivitySession.fromJson(Map<dynamic, dynamic> json) {
    final localSessionId = json['localSessionId'];
    if (localSessionId is! String || localSessionId.isEmpty) {
      throw const FormatException(
        'Missing active session field: localSessionId',
      );
    }
    final startedAt = jsonDateTime(json['startedAt']);
    if (startedAt == null) {
      throw const FormatException('Invalid active session field: startedAt');
    }

    return ActiveActivitySession(
      localSessionId: localSessionId,
      activityType: ActivityType.fromApiValue(jsonString(json['activityType'])),
      status: ActiveActivityStatus.fromJson(json['status']),
      startedAt: startedAt,
      resumedAt: jsonDateTime(json['resumedAt']),
      pausedAt: jsonDateTime(json['pausedAt']),
      endedAt: jsonDateTime(json['endedAt']),
      elapsedDurationSeconds: jsonInt(json['elapsedDurationSeconds']) ?? 0,
      currentSegmentIndex: jsonInt(json['currentSegmentIndex']) ?? 0,
      schemaVersion: jsonInt(json['schemaVersion']) ?? currentSchemaVersion,
    );
  }
}
