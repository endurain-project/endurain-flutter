import 'package:endurain/core/utils/copy_with.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_type.dart';

/// Test-only conveniences for [ActiveActivitySession], which production code
/// never copies or inspects (recording state is owned by the native recorder).
extension ActiveActivitySessionTestX on ActiveActivitySession {
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
}
