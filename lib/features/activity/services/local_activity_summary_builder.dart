import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/services/activity_stats_calculator.dart';

class LocalActivitySummaryBuilder {
  LocalActivitySummaryBuilder({ActivityStatsCalculator? statsCalculator})
    : _statsCalculator = statsCalculator ?? ActivityStatsCalculator();

  final ActivityStatsCalculator _statsCalculator;

  LocalActivityRecord build({
    required ActivityRecordingState state,
    required String id,
    required String gpxFileName,
    required DateTime createdAt,
  }) {
    if (state.status != ActivityRecordingStatus.completed) {
      throw const AppException(AppErrorCode.activityLocalRecordInvalid);
    }

    final points = state.points;
    final startedAt =
        state.startedAt ??
        (points.isEmpty ? createdAt : points.first.timestamp);
    var endedAt =
        state.endedAt ?? (points.isEmpty ? startedAt : points.last.timestamp);
    if (endedAt.isBefore(startedAt)) {
      endedAt = startedAt;
    }

    final stats = _statsCalculator.calculate(state.segments);
    final elapsedDurationSeconds = state.elapsedDurationSeconds < 0
        ? 0
        : state.elapsedDurationSeconds;

    return LocalActivityRecord(
      id: id,
      activityType: state.activityType ?? ActivityType.other,
      startedAt: startedAt.toUtc(),
      endedAt: endedAt.toUtc(),
      elapsedDurationSeconds: elapsedDurationSeconds,
      distanceMeters: stats.distanceMeters,
      averageSpeedMetersPerSecond: stats.averageSpeedMetersPerSecond,
      maxSpeedMetersPerSecond: stats.maxSpeedMetersPerSecond,
      elevationGainMeters: stats.elevationGainMeters,
      pointCount: points.length,
      gpxFileName: gpxFileName,
      uploadStatus: LocalActivityUploadStatus.pending,
      createdAt: createdAt.toUtc(),
      updatedAt: createdAt.toUtc(),
    );
  }
}
