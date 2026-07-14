import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/gpx_document_builder.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_workout.dart';

/// Converts a [HealthWorkout] into a GPX 1.1 string for upload to the
/// Endurain server.
///
/// The output includes standard track-point extensions for heart rate
/// (`gpxtpx:TrackPointExtension / gpxtpx:hr`) when the route points carry
/// heart rate data.
///
/// Throws [AppException] with [AppErrorCode.healthGpxBuildFailed] if the
/// workout has no route points (caller should guard against this with
/// [HealthWorkout.hasRoute] before calling).
class HealthWorkoutGpxBuilder {
  const HealthWorkoutGpxBuilder();

  /// Builds a GPX 1.1 document from [workout].
  ///
  /// Throws [AppException] with [AppErrorCode.healthGpxBuildFailed] if
  /// [HealthWorkout.hasRoute] is false.
  String build(HealthWorkout workout) {
    if (!workout.hasRoute) {
      throw AppException(
        AppErrorCode.healthGpxBuildFailed,
        details: 'workout has no GPS route: ${workout.sourceId}',
      );
    }

    try {
      final trackType = workout.type.toActivityType().apiValue;
      return buildGpxDocument(
        name: trackType,
        type: trackType,
        metadataTime: workout.startedAt,
        segments: [workout.route.map(_toGpxPoint).toList(growable: false)],
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(AppErrorCode.healthGpxBuildFailed, cause: e);
    }
  }

  GpxTrackPoint _toGpxPoint(HealthRoutePoint point) => GpxTrackPoint(
    latitude: point.latitude,
    longitude: point.longitude,
    elevationMeters: point.elevation,
    time: point.time,
    heartRate: point.heartRate,
  );
}
