import 'package:endurain/features/activity/models/activity_type.dart';

/// Lifecycle status of an active (in-progress or recoverable) recording.
///
/// This is intentionally independent from any UI display strings so the model
/// can be persisted and recovered without coupling to localization.
enum ActiveActivityStatus {
  recording,
  paused,
  stopping,
  completed,
  failed;

  static ActiveActivityStatus fromJson(Object? value) {
    for (final status in values) {
      if (status.name == value) {
        return status;
      }
    }
    return ActiveActivityStatus.failed;
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
    Object? resumedAt = _unset,
    Object? pausedAt = _unset,
    Object? endedAt = _unset,
    int? elapsedDurationSeconds,
    int? currentSegmentIndex,
    int? schemaVersion,
  }) {
    return ActiveActivitySession(
      localSessionId: localSessionId ?? this.localSessionId,
      activityType: activityType ?? this.activityType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      resumedAt: identical(resumedAt, _unset)
          ? this.resumedAt
          : resumedAt as DateTime?,
      pausedAt: identical(pausedAt, _unset)
          ? this.pausedAt
          : pausedAt as DateTime?,
      endedAt: identical(endedAt, _unset) ? this.endedAt : endedAt as DateTime?,
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
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (resumedAt != null) 'resumedAt': resumedAt!.toUtc().toIso8601String(),
      if (pausedAt != null) 'pausedAt': pausedAt!.toUtc().toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toUtc().toIso8601String(),
      'elapsedDurationSeconds': elapsedDurationSeconds,
      'currentSegmentIndex': currentSegmentIndex,
    };
  }

  factory ActiveActivitySession.fromJson(Map<dynamic, dynamic> json) {
    final localSessionId = json['localSessionId'];
    if (localSessionId is! String || localSessionId.isEmpty) {
      throw const FormatException('Missing active session field: localSessionId');
    }
    final startedAt = _dateTime(json['startedAt']);
    if (startedAt == null) {
      throw const FormatException('Invalid active session field: startedAt');
    }

    return ActiveActivitySession(
      localSessionId: localSessionId,
      activityType: ActivityType.fromApiValue(_string(json['activityType'])),
      status: ActiveActivityStatus.fromJson(json['status']),
      startedAt: startedAt,
      resumedAt: _dateTime(json['resumedAt']),
      pausedAt: _dateTime(json['pausedAt']),
      endedAt: _dateTime(json['endedAt']),
      elapsedDurationSeconds: _int(json['elapsedDurationSeconds']) ?? 0,
      currentSegmentIndex: _int(json['currentSegmentIndex']) ?? 0,
      schemaVersion: _int(json['schemaVersion']) ?? currentSchemaVersion,
    );
  }

  static const Object _unset = Object();
}

String? _string(Object? value) => value is String ? value : null;

int? _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

DateTime? _dateTime(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value)?.toUtc();
}
