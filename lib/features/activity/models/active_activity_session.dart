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
    this.connectionOrigin,
    this.connectionProfileId,
    this.heartRateDeviceId,
    this.powerDeviceId,
    this.cadenceDeviceId,
    this.resumedAt,
    this.pausedAt,
    this.endedAt,
    this.elapsedDurationSeconds = 0,
    this.currentSegmentIndex = 0,
    this.autoPauseEnabled = false,
    this.autoPauseDelaySeconds = 5,
    this.pausedAutomatically = false,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 3;

  final String localSessionId;
  final ActivityType activityType;
  final ActiveActivityStatus status;
  final DateTime startedAt;
  final String? connectionOrigin;
  final String? connectionProfileId;

  /// Identifiers of the external BLE sensors bound to this recording.
  ///
  /// The native Android/iOS recorders persist these in `session.json` so a
  /// sticky restart can reconnect the same straps. They are part of the same
  /// `schemaVersion` and must round-trip here too: dropping them on a Dart
  /// write would silently unbind the sensors from a recoverable session.
  final String? heartRateDeviceId;
  final String? powerDeviceId;
  final String? cadenceDeviceId;
  final DateTime? resumedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final int elapsedDurationSeconds;
  final int currentSegmentIndex;

  /// Snapshot of the auto-pause preference in effect when this recording
  /// started (see `AutoPauseSettingsRepository`), so a recovered recording
  /// keeps behaving the way it did when it started even if the user later
  /// changes the app preference. `false` (and a schema version below 3) means
  /// a session persisted before auto-pause existed — treated as disabled
  /// rather than defaulting to the current preference, so an in-flight
  /// recording's behavior never silently changes underneath an app update.
  final bool autoPauseEnabled;

  /// Snapshot of the configured stillness delay (seconds) in effect when this
  /// recording started. Only meaningful when [autoPauseEnabled] is `true`.
  final int autoPauseDelaySeconds;

  /// Whether the current [ActiveActivityStatus.paused] session was paused
  /// automatically (by the movement detector) rather than by explicit user
  /// action. Meaningless when [status] is not [ActiveActivityStatus.paused].
  ///
  /// This is the durable half of the manual/automatic distinction: a manual
  /// pause never auto-resumes because the recorder stops monitoring location
  /// entirely (see the recorder implementations), but this flag also lets a
  /// recovered session (e.g. after the app was killed while auto-paused)
  /// preserve that it should show as auto-paused rather than manually paused.
  final bool pausedAutomatically;

  final int schemaVersion;

  bool get isActive =>
      status == ActiveActivityStatus.recording ||
      status == ActiveActivityStatus.paused;

  ActiveActivitySession copyWith({
    String? localSessionId,
    ActivityType? activityType,
    ActiveActivityStatus? status,
    DateTime? startedAt,
    Object? connectionOrigin = kUnset,
    Object? connectionProfileId = kUnset,
    Object? heartRateDeviceId = kUnset,
    Object? powerDeviceId = kUnset,
    Object? cadenceDeviceId = kUnset,
    Object? resumedAt = kUnset,
    Object? pausedAt = kUnset,
    Object? endedAt = kUnset,
    int? elapsedDurationSeconds,
    int? currentSegmentIndex,
    bool? autoPauseEnabled,
    int? autoPauseDelaySeconds,
    bool? pausedAutomatically,
    int? schemaVersion,
  }) {
    return ActiveActivitySession(
      localSessionId: localSessionId ?? this.localSessionId,
      activityType: activityType ?? this.activityType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      connectionOrigin: identical(connectionOrigin, kUnset)
          ? this.connectionOrigin
          : connectionOrigin as String?,
      connectionProfileId: identical(connectionProfileId, kUnset)
          ? this.connectionProfileId
          : connectionProfileId as String?,
      heartRateDeviceId: identical(heartRateDeviceId, kUnset)
          ? this.heartRateDeviceId
          : heartRateDeviceId as String?,
      powerDeviceId: identical(powerDeviceId, kUnset)
          ? this.powerDeviceId
          : powerDeviceId as String?,
      cadenceDeviceId: identical(cadenceDeviceId, kUnset)
          ? this.cadenceDeviceId
          : cadenceDeviceId as String?,
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
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      autoPauseDelaySeconds:
          autoPauseDelaySeconds ?? this.autoPauseDelaySeconds,
      pausedAutomatically: pausedAutomatically ?? this.pausedAutomatically,
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
      if (connectionOrigin != null) 'connectionOrigin': connectionOrigin,
      if (connectionProfileId != null)
        'connectionProfileId': connectionProfileId,
      // Short keys mirror the native `ActiveRecordingModels` serialization.
      if (heartRateDeviceId != null) 'hrDeviceId': heartRateDeviceId,
      if (powerDeviceId != null) 'powerDeviceId': powerDeviceId,
      if (cadenceDeviceId != null) 'cadenceDeviceId': cadenceDeviceId,
      if (resumedAt != null) 'resumedAt': resumedAt!.toUtcIso8601(),
      if (pausedAt != null) 'pausedAt': pausedAt!.toUtcIso8601(),
      if (endedAt != null) 'endedAt': endedAt!.toUtcIso8601(),
      'elapsedDurationSeconds': elapsedDurationSeconds,
      'currentSegmentIndex': currentSegmentIndex,
      'autoPauseEnabled': autoPauseEnabled,
      'autoPauseDelaySeconds': autoPauseDelaySeconds,
      'pausedAutomatically': pausedAutomatically,
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
      connectionOrigin: jsonString(json['connectionOrigin']),
      connectionProfileId: jsonString(json['connectionProfileId']),
      heartRateDeviceId: jsonString(json['hrDeviceId']),
      powerDeviceId: jsonString(json['powerDeviceId']),
      cadenceDeviceId: jsonString(json['cadenceDeviceId']),
      resumedAt: jsonDateTime(json['resumedAt']),
      pausedAt: jsonDateTime(json['pausedAt']),
      endedAt: jsonDateTime(json['endedAt']),
      elapsedDurationSeconds: jsonInt(json['elapsedDurationSeconds']) ?? 0,
      currentSegmentIndex: jsonInt(json['currentSegmentIndex']) ?? 0,
      // Absent on sessions persisted before schema version 3 (or by a native
      // recorder build that predates auto-pause): default to disabled rather
      // than the current app preference, so an in-flight recording recovered
      // after an app update never silently starts auto-pausing.
      autoPauseEnabled: jsonBool(json['autoPauseEnabled']) ?? false,
      autoPauseDelaySeconds: jsonInt(json['autoPauseDelaySeconds']) ?? 5,
      pausedAutomatically: jsonBool(json['pausedAutomatically']) ?? false,
      schemaVersion: jsonInt(json['schemaVersion']) ?? currentSchemaVersion,
    );
  }
}
